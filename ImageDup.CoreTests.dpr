program ImageDup.CoreTests;
{$APPTYPE CONSOLE}
uses System.SysUtils, System.Generics.Collections, Vcl.Graphics,
  ImageDup.Core in 'ImageDup.Core.pas', ImageDup.Groups in 'ImageDup.Groups.pas';
procedure Check(Value: Boolean; const Why: string);
begin if not Value then raise Exception.Create(Why) end;
procedure TestCollisions;
var
  A, B: TBitmap;
  SA, SB: TImageSignature;
  M: TComparison;
  X, Y, Mode: Integer;
  LowColor, HighColor: TColor;
begin
  A := TBitmap.Create;
  B := TBitmap.Create;
  try
    A.SetSize(64,64); B.SetSize(64,64);
    for Mode := 0 to 1 do
    begin
      LowColor := clBlack; HighColor := clWhite;
      if Mode = 1 then begin LowColor := $006C6C6C; HighColor := $00949494 end;
      A.Canvas.Brush.Color := clGray; A.Canvas.FillRect(A.Canvas.ClipRect);
      B.Canvas.Brush.Color := clGray; B.Canvas.FillRect(B.Canvas.ClipRect);
      for Y := 0 to 63 do
        for X := 0 to 63 do
          if (Mode = 0) or ((X < 8) and (Y < 8)) then
          begin
            if Odd(X) then
            begin A.Canvas.Pixels[X,Y] := HighColor; B.Canvas.Pixels[X,Y] := LowColor end
            else
            begin A.Canvas.Pixels[X,Y] := LowColor; B.Canvas.Pixels[X,Y] := HighColor end;
          end;
      SA := SignatureFromGraphic(A); SB := SignatureFromGraphic(B);
      Check(HashDistance(SA.Hash,SB.Hash) = 0, 'Expected identical low-frequency hashes');
      Check(PixelError(SA,SB) = 0, 'Expected identical reduced RGB');
      Check(not CompareSignatures(SA,SB,1,0.08,M), 'False positive survives detailed comparison');
      StructuralMetrics(SA,SB,M);
      if Mode = 1 then
      begin
        Check(M.Structural >= MinStructuralSimilarity, 'Fixture must pass the mean threshold');
        Check(M.WorstStructural < MinLocalSimilarity, 'Local damage must fail the worst-block check');
      end;
      Check(CompareSignatures(SA,SA,0,0,M), 'Exact copy rejected');
      Check(Abs(M.Structural - 1) < 1E-10, 'Exact copy SSIM must be 1');
    end;
    Writeln('PASS: hash/RGB collisions, high-frequency differences, local differences, exact copies.');
  finally B.Free; A.Free end;
end;
procedure TestGroups;
var
  Builder: TGroupBuilder;
  Matches: TDictionary<Integer,TComparison>;
  Info: TImageInfo;
  M: TComparison;
  Id: Integer;
  G: TImageGroup;
begin
  Builder := TGroupBuilder.Create;
  Matches := TDictionary<Integer,TComparison>.Create;
  try
    Info := Default(TImageInfo); M := Default(TComparison);
    Info.FileName := 'A'; Check(Builder.Add(Info,Matches) = -1, 'Singleton shown');
    Matches.Add(0,M); Info.FileName := 'B'; Id := Builder.Add(Info,Matches);
    Check(Length(Builder.Snapshot(Id).Members) = 2, 'A and B not grouped');
    Matches.Clear; Matches.Add(1,M); Info.FileName := 'C';
    Check(Builder.Add(Info,Matches) = -1, 'A-B-C transitive chain merged');
    Matches.Clear; Matches.Add(0,M); Matches.Add(1,M); Info.FileName := 'D';
    Id := Builder.Add(Info,Matches); G := Builder.Snapshot(Id);
    Check(Length(G.Members) = 3, 'Fully verified member not added');
    Check(G.Members[2].Info.FileName = 'D', 'Wrong member');
    Check((G.Members[0].ExactClass = G.Members[1].ExactClass) and
      (G.Members[1].ExactClass = G.Members[2].ExactClass),
      'Exact-content class was not propagated');
    Matches.Clear; Matches.Add(2,M); Info.FileName := 'E';
    Id := Builder.Add(Info,Matches); G := Builder.Snapshot(Id);
    Check(Length(G.Members) = 2, 'Second group missing');
    Check(G.Members[0].Info.FileName = 'C', 'Wrong second group');
    Writeln('PASS: groups, singleton hiding, no transitive chaining, multiple groups.');
  finally Matches.Free; Builder.Free end;
end;

procedure TestQualityRanking;
var G: TImageGroup; ScoreBeforeDpi: Double;
begin
  G := Default(TImageGroup);
  SetLength(G.Members, 2);
  G.Members[0].Info.FileName := 'low';
  G.Members[0].Info.Width := 1000;
  G.Members[0].Info.Height := 1000;
  G.Members[0].Info.Quality.Sharpness := 0.10;
  G.Members[0].Info.Quality.Noise := 0.20;
  G.Members[0].Info.Quality.BlockArtifacts := 0.15;
  G.Members[0].Info.Quality.BitDepth := 8;
  G.Members[0].Info.Quality.ChromaSubsampling := cs420;
  G.Members[1].Info.FileName := 'high';
  G.Members[1].Info.Width := 2000;
  G.Members[1].Info.Height := 2000;
  G.Members[1].Info.Quality.Sharpness := 0.20;
  G.Members[1].Info.Quality.Noise := 0.05;
  G.Members[1].Info.Quality.BlockArtifacts := 0.02;
  G.Members[1].Info.Quality.BitDepth := 12;
  G.Members[1].Info.Quality.HasColorProfile := True;
  G.Members[1].Info.Quality.ChromaSubsampling := cs444;
  CalculateGroupQuality(G);
  Check(G.Members[0].Info.FileName = 'high',
    'Highest-quality image is not the group reference');
  Check((G.Members[0].QualityScore >= 0) and
    (G.Members[1].QualityScore <= 100), 'Quality score outside 0..100');
  Check(G.Members[0].QualityScore > G.Members[1].QualityScore,
    'Better image ranked below lower-quality image');
  ScoreBeforeDpi := G.Members[0].QualityScore;
  G.Members[0].Info.DpiX := 1200;
  G.Members[0].Info.DpiY := 1200;
  CalculateGroupQuality(G);
  Check(Abs(G.Members[0].QualityScore - ScoreBeforeDpi) < 1E-10,
    'DPI incorrectly affects quality score');
  Writeln('PASS: group quality ranking and DPI independence.');
end;
begin
  try TestCollisions; TestGroups; TestQualityRanking;
  except on E: Exception do begin Writeln('FAIL: ',E.Message); ExitCode := 1 end end;
end.
