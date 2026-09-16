unit ImageDup.Groups;

interface

uses System.SysUtils, System.Generics.Collections, ImageDup.Core;

type
  TImageInfo = record
    FileName: string;
    Width, Height: Integer;
    DpiX, DpiY: Double;
    Bytes: Int64;
    Modified: TDateTime;
    Quality: TImageQualityMetrics;
  end;
  TGroupMember = record
    ImageIndex: Integer;
    ExactClass: Integer; // Equivalence class for pixel-identical signatures.
    Info: TImageInfo;
    Metrics: TComparison; // Relative to the first member (reference).
    QualityScore: Double; // Relative technical ranking, 0..100.
    HasIdenticalPeer: Boolean;
    IsReference: Boolean;
  end;

  TImageGroup = record
    Id: Integer;
    Members: TArray<TGroupMember>;
  end;
  TGroupBuilder = class
  private
    FGroups: TObjectList<TList<TGroupMember>>;
    FNextIndex: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    // Only join a group when every member has a verified match. Groups are
    // disjoint, first-fit and order-dependent; similarity is not transitive.
    function Add(const Info: TImageInfo;
      Matches: TDictionary<Integer, TComparison>): Integer;
    function Snapshot(Id: Integer): TImageGroup;
  end;

procedure CalculateGroupQuality(var Group: TImageGroup);

implementation

uses System.Math;

const
  ResolutionWeight = 24.0;
  SharpnessWeight = 24.0;
  ArtifactWeight = 14.0;
  NoiseWeight = 10.0;
  DepthWeight = 7.0;
  ProfileWeight = 3.0;
  ClippingWeight = 7.0;
  BandingWeight = 5.0;
  UpscaleWeight = 4.0;
  ChromaWeight = 2.0;

function DepthFactor(BitDepth: Integer): Double;
begin
  if BitDepth <= 0 then Result := 0.70
  else if BitDepth <= 8 then Result := 0.75
  else if BitDepth <= 10 then Result := 0.88
  else if BitDepth <= 12 then Result := 0.94
  else Result := 1;
end;

function ChromaFactor(Value: TChromaSubsampling): Double;
begin
  case Value of
    cs420: Result := 0.60;
    cs422: Result := 0.80;
    cs444: Result := 1.00;
    csGray, csNotApplicable: Result := 0.90;
    csOther: Result := 0.70;
  else
    Result := 0.75;
  end;
end;

procedure CalculateGroupQuality(var Group: TImageGroup);
var
    I, J: Integer;
  MaxPixels: Int64;
  MaxSharpness, ResolutionFactor, SharpnessFactor, ProfileFactor: Double;
  Q: TImageQualityMetrics;
  SwapMember: TGroupMember;
begin
  MaxPixels := 0;
  MaxSharpness := 0;
  for I := 0 to High(Group.Members) do begin
    MaxPixels := Max(MaxPixels, Int64(Group.Members[I].Info.Width) *
      Group.Members[I].Info.Height);
    MaxSharpness := Max(MaxSharpness, Group.Members[I].Info.Quality.Sharpness);
  end;
  for I := 0 to High(Group.Members) do begin
    Q := Group.Members[I].Info.Quality;
    if MaxPixels > 0 then
      ResolutionFactor := Sqrt((Int64(Group.Members[I].Info.Width) *
        Group.Members[I].Info.Height) / MaxPixels)
    else ResolutionFactor := 0;
    if MaxSharpness > 1E-12 then SharpnessFactor := Q.Sharpness / MaxSharpness
    else SharpnessFactor := 0.5;
    if Q.HasColorProfile then ProfileFactor := 1 else ProfileFactor := 0.8;
    Group.Members[I].QualityScore := EnsureRange(
      ResolutionWeight * ResolutionFactor +
      SharpnessWeight * SharpnessFactor +
      ArtifactWeight * (1 - Q.BlockArtifacts) +
      NoiseWeight * (1 - Q.Noise) +
      DepthWeight * DepthFactor(Q.BitDepth) +
      ProfileWeight * ProfileFactor +
      ClippingWeight * (1 - Q.Clipping) +
      BandingWeight * (1 - Q.Banding) +
      UpscaleWeight * (1 - Q.UpscaleRisk) +
      ChromaWeight * ChromaFactor(Q.ChromaSubsampling), 0.0, 100.0);
  end;
    // Stable descending order: the first member is the reference.
    for I := 1 to High(Group.Members) do begin
      SwapMember := Group.Members[I];
      J := I - 1;
      while (J >= 0) and
        (Group.Members[J].QualityScore < SwapMember.QualityScore) do begin
        Group.Members[J + 1] := Group.Members[J];
        Dec(J);
      end;
      Group.Members[J + 1] := SwapMember;
    end;
    for I := 0 to High(Group.Members) do
      Group.Members[I].IsReference := I = 0;
end;

constructor TGroupBuilder.Create;
begin
  inherited;
  FGroups := TObjectList<TList<TGroupMember>>.Create(True);
end;

destructor TGroupBuilder.Destroy;
begin
  FGroups.Free;
  inherited;
end;

function TGroupBuilder.Add(const Info: TImageInfo;
  Matches: TDictionary<Integer, TComparison>): Integer;
var
  I, J: Integer;
  Fits: Boolean;
  Member, Existing: TGroupMember;
  PairMetrics: TComparison;
  Group: TList<TGroupMember>;
begin
  Member := Default(TGroupMember);
  Member.Info := Info;
  Member.ImageIndex := FNextIndex;
  Member.ExactClass := FNextIndex;
  Inc(FNextIndex);
  for I := 0 to FGroups.Count - 1 do
  begin
    Group := FGroups[I];
    Fits := True;
    for Existing in Group do
      if not Matches.ContainsKey(Existing.ImageIndex) then
      begin
        Fits := False;
        Break;
      end;
    if Fits then
    begin
      Member.Metrics := Matches[Group[0].ImageIndex];
      for J := 0 to Group.Count - 1 do begin
        PairMetrics := Matches[Group[J].ImageIndex];
        if (PairMetrics.Distance = 0) and (PairMetrics.RGBError <= 1E-12) then
        begin
          Member.ExactClass := Group[J].ExactClass;
          Member.HasIdenticalPeer := True;
          Existing := Group[J];
          Existing.HasIdenticalPeer := True;
          Group[J] := Existing;
        end;
      end;
      Group.Add(Member);
      Exit(I);
    end;
  end;
  Group := TList<TGroupMember>.Create;
  FGroups.Add(Group);
  Member.Metrics.Structural := 1;
  Member.Metrics.WorstStructural := 1;
  Group.Add(Member);
  Result := -1; // Singletons are retained internally, but not shown as groups.
end;

function TGroupBuilder.Snapshot(Id: Integer): TImageGroup;
begin
  Result.Id := Id;
  Result.Members := FGroups[Id].ToArray;
  CalculateGroupQuality(Result);
end;

end.
