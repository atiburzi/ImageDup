unit ImageDup.Core;

interface

uses System.SysUtils, System.Classes, Vcl.Graphics;

const
  SampleSize = 32;
  DetailSize = 64;
  MinStructuralSimilarity = 0.97;
  MinLocalSimilarity = 0.80;
  MaxLocalRGBError = 0.18;
  DefaultMaxRGBError = 0.08;
  MinComparisonQuality = 0;
  MaxComparisonQuality = 10;
  MaxHashDistance = 63;

type
  TChromaSubsampling = (csUnknown, csNotApplicable, csGray, cs420, cs422,
    cs444, csOther);
  TImageColorMode = (icmUnknown, icmMonochrome, icmGrayscale, icmColor);

  TImageQualityMetrics = record
    // Pixel-derived values are normalized to 0..1. Higher Sharpness is better;
    // for the other values, higher means a stronger defect/risk.
    Sharpness: Double;
    Noise: Double;
    BlockArtifacts: Double;
    Clipping: Double;
    Banding: Double;
    UpscaleRisk: Double;
    BitDepth: Integer;
    HasColorProfile: Boolean;
    ChromaSubsampling: TChromaSubsampling;
    ColorMode: TImageColorMode;
  end;

  TImageSignature = record
    Hash: UInt64;
    DetailRGB: array[0..DetailSize * DetailSize * 3 - 1] of Byte;
    DetailGray: array[0..DetailSize * DetailSize - 1] of Byte;
    RGB: array[0..SampleSize * SampleSize * 3 - 1] of Byte;
    Quality: TImageQualityMetrics;
  end;

  TComparison = record
    Distance: Integer;
    RGBError, Structural, WorstStructural, WorstRGB: Double;
  end;

function CompareSignatures(const A, B: TImageSignature; MaxDistance: Integer;
  MaxRGBError: Double; out Metrics: TComparison): Boolean;
procedure StructuralMetrics(const A, B: TImageSignature; out Metrics: TComparison);
function SignatureFromGraphic(Graphic: TGraphic): TImageSignature;
function IsSupportedImageFile(const FileName: string): Boolean;
procedure LoadImagePreview(const FileName: string; Picture: TPicture);
function LoadSignature(const FileName: string): TImageSignature; overload;
function LoadSignature(const FileName: string; out Width, Height: Integer): TImageSignature; overload;
function LoadSignature(const FileName: string; out Width, Height: Integer;
  out DpiX, DpiY: Double): TImageSignature; overload;
function HashDistance(A, B: UInt64): Integer;
function ComparisonQualityToDistance(Quality: Integer): Integer;
function DistanceToComparisonQuality(Distance: Integer): Integer;
function PixelError(const A, B: TImageSignature): Double;
function ChromaSubsamplingText(Value: TChromaSubsampling): string;
function ImageColorModeText(Value: TImageColorMode): string;

implementation

uses System.Math, System.Types, System.Win.ComObj, Winapi.Windows, Winapi.ActiveX, Winapi.Wincodec,
  Vcl.Imaging.jpeg, Vcl.Imaging.pngimage;

type
  TPixelRow = array[0..MaxInt div SizeOf(TRGBTriple) - 1] of TRGBTriple;
  PPixelRow = ^TPixelRow;

const
  PF_POPCNT_INSTRUCTION_AVAILABLE = 23;

resourcestring
  rsChromaGray='grayscale';
  rsChromaOther='other';
  rsColorModeColor='color';
  rsColorModeGrayscale='grayscale';
  rsColorModeMonochrome='monochrome';
  rsUnknown='unknown';
  rsTruncatedJpeg='Truncated JPEG file';
  rsEmptyImage='Empty image';
  rsInvalidImageDimensions='Invalid image dimensions';
  rsImageTooLarge='Image is too large';
  rsImageDecoderUnavailable = 'No Windows WIC decoder is available for %s. Install or enable a compatible image extension (WebP or HEIF/HEVC for those formats).';

var
  GCosines: array[0..7, 0..31] of Double;
  GPopCntAvailable: Boolean;

function IsSupportedImageFile(const FileName: string): Boolean;
var
  Ext: string;
begin
  Ext := LowerCase(ExtractFileExt(FileName));
  Result := (Ext = '.jpg') or (Ext = '.jpeg') or (Ext = '.png') or
    (Ext = '.bmp') or (Ext = '.gif') or (Ext = '.tif') or
    (Ext = '.tiff') or (Ext = '.webp') or (Ext = '.heic') or
    (Ext = '.heif');
end;

function ComparisonQualityToDistance(Quality: Integer): Integer;
begin
  Quality := EnsureRange(Quality, MinComparisonQuality,
    MaxComparisonQuality);
  Result := ((MaxComparisonQuality - Quality) * MaxHashDistance +
    MaxComparisonQuality div 2) div MaxComparisonQuality;
end;

function DistanceToComparisonQuality(Distance: Integer): Integer;
begin
  Distance := EnsureRange(Distance, 0, MaxHashDistance);
  Result := ((MaxHashDistance - Distance) * MaxComparisonQuality +
    MaxHashDistance div 2) div MaxHashDistance;
end;
function ChromaSubsamplingText(Value: TChromaSubsampling): string;
begin
  case Value of
    csNotApplicable: Result := '-';
    csGray: Result := rsChromaGray;
    cs420: Result := '4:2:0';
    cs422: Result := '4:2:2';
    cs444: Result := '4:4:4';
    csOther: Result := rsChromaOther;
  else
    Result := rsUnknown;
  end;
end;

function ImageColorModeText(Value: TImageColorMode): string;
begin
  case Value of
    icmMonochrome: Result := rsColorModeMonochrome;
    icmGrayscale: Result := rsColorModeGrayscale;
    icmColor: Result := rsColorModeColor;
  else
    Result := rsUnknown;
  end;
end;

procedure DetectSignatureColorMode(var Signature: TImageSignature);
const
  ColorTolerance = 8;
  MinimumColorRatio = 0.01;
var
  Histogram: array[0..255] of Boolean;
  I, Red, Green, Blue, Luma, Occupied, ColorCount, PixelCount: Integer;
begin
  FillChar(Histogram, SizeOf(Histogram), 0);
  ColorCount := 0;
  PixelCount := DetailSize * DetailSize;
  for I := 0 to PixelCount - 1 do
  begin
    Red := Signature.DetailRGB[I * 3];
    Green := Signature.DetailRGB[I * 3 + 1];
    Blue := Signature.DetailRGB[I * 3 + 2];
    if Max(Max(Red, Green), Blue) - Min(Min(Red, Green), Blue) >
      ColorTolerance then
      Inc(ColorCount);
    Luma := Signature.DetailGray[I];
    Histogram[Luma] := True;
  end;
  if ColorCount / PixelCount >= MinimumColorRatio then
    Signature.Quality.ColorMode := icmColor
  else
  begin
    Occupied := 0;
    for I := 0 to High(Histogram) do
      if Histogram[I] then
        Inc(Occupied);
    if Occupied <= 2 then
      Signature.Quality.ColorMode := icmMonochrome
    else
      Signature.Quality.ColorMode := icmGrayscale;
  end;
end;

function PixelLuma(const Pixels: TBytes; Offset: NativeInt): Integer; inline;
var Alpha: Integer;
begin
  Alpha := Pixels[Offset + 3];
  Result := (29 * (Pixels[Offset] * Alpha + 255 * (255 - Alpha)) div 255 +
    150 * (Pixels[Offset + 1] * Alpha + 255 * (255 - Alpha)) div 255 +
    77 * (Pixels[Offset + 2] * Alpha + 255 * (255 - Alpha)) div 255 + 128) shr 8;
end;

procedure AnalyzePixels(const Pixels: TBytes; Width, Height, Stride: Integer;
  var Quality: TImageQualityMetrics);
const MaxSamples = 500000;
var
  X, Y, Step, C, L, R, U, D, Lap, Grad, Delta, I, Offset,
    Alpha, PixelRed, PixelGreen, PixelBlue: Integer;
  Count, FlatCount, ClipCount, RepeatCount, TransitionCount,
    SmallTransitionCount, BoundaryCount, InteriorCount, Occupied,
    ColorCount: Int64;
  LapSquares, NoiseTotal, BoundaryTotal, InteriorTotal: Double;
  Histogram: array[0..255] of Integer;
  RepeatRatio, BoundaryAverage, InteriorAverage: Double;
begin
  Quality.Sharpness := 0;
  Quality.Noise := 0;
  Quality.BlockArtifacts := 0;
  Quality.Clipping := 0;
  Quality.Banding := 0;
  Quality.UpscaleRisk := 0;
  Quality.ColorMode := icmUnknown;
  if (Width < 3) or (Height < 3) then Exit;
  Step := Max(1, Ceil(Sqrt((Int64(Width) * Height) / MaxSamples)));
  Count := 0; FlatCount := 0; ClipCount := 0; RepeatCount := 0;
  ColorCount := 0;
  TransitionCount := 0; SmallTransitionCount := 0;
  BoundaryCount := 0; InteriorCount := 0;
  LapSquares := 0; NoiseTotal := 0; BoundaryTotal := 0; InteriorTotal := 0;
  FillChar(Histogram, SizeOf(Histogram), 0);
  Y := Step;
  while Y < Height - Step do
  begin
    X := Step;
    while X < Width - Step do
    begin
      Offset := NativeInt(Y) * Stride + NativeInt(X) * 4;
      C := PixelLuma(Pixels, Offset);
      Alpha := Pixels[Offset + 3];
      PixelBlue := (Pixels[Offset] * Alpha + 255 * (255 - Alpha) + 127) div 255;
      PixelGreen := (Pixels[Offset + 1] * Alpha + 255 * (255 - Alpha) + 127) div 255;
      PixelRed := (Pixels[Offset + 2] * Alpha + 255 * (255 - Alpha) + 127) div 255;
      if Max(Max(PixelRed, PixelGreen), PixelBlue) -
        Min(Min(PixelRed, PixelGreen), PixelBlue) > 8 then
        Inc(ColorCount);
      L := PixelLuma(Pixels, NativeInt(Y) * Stride + NativeInt(X - Step) * 4);
      R := PixelLuma(Pixels, NativeInt(Y) * Stride + NativeInt(X + Step) * 4);
      U := PixelLuma(Pixels, NativeInt(Y - Step) * Stride + NativeInt(X) * 4);
      D := PixelLuma(Pixels, NativeInt(Y + Step) * Stride + NativeInt(X) * 4);
      Lap := 4 * C - L - R - U - D;
      LapSquares := LapSquares + Int64(Lap) * Lap;
      Grad := Max(Abs(R - L), Abs(D - U));
      if Grad <= 18 then begin Inc(FlatCount); NoiseTotal := NoiseTotal + Abs(Lap) end;
      if (C <= 2) or (C >= 253) then Inc(ClipCount);
      Inc(Histogram[C]);
      Delta := Abs(C - L);
      if Abs(C - PixelLuma(Pixels, NativeInt(Y) * Stride +
        NativeInt(X - 1) * 4)) <= 1 then Inc(RepeatCount);
      if Delta > 0 then begin
        Inc(TransitionCount);
        if Delta <= 2 then Inc(SmallTransitionCount);
      end;
      if (X mod 8 = 0) then begin Inc(BoundaryCount); BoundaryTotal := BoundaryTotal + Delta end
      else begin Inc(InteriorCount); InteriorTotal := InteriorTotal + Delta end;
      Inc(Count);
      Inc(X, Step);
    end;
    Inc(Y, Step);
  end;
  if Count = 0 then Exit;
  Quality.Sharpness := EnsureRange(Sqrt(LapSquares / Count) / 255, 0.0, 1.0);
  if FlatCount > 0 then
    Quality.Noise := EnsureRange((NoiseTotal / FlatCount) / 32, 0.0, 1.0);
  if (BoundaryCount > 0) and (InteriorCount > 0) then begin
    BoundaryAverage := BoundaryTotal / BoundaryCount;
    InteriorAverage := InteriorTotal / InteriorCount;
    Quality.BlockArtifacts := EnsureRange(
      (BoundaryAverage - InteriorAverage) / 24, 0.0, 1.0);
  end;
  Quality.Clipping := ClipCount / Count;
  Occupied := 0;
  for I := 0 to 255 do
    if Histogram[I] > 0 then
      Inc(Occupied);
  if TransitionCount > 0 then
    Quality.Banding := EnsureRange((SmallTransitionCount / TransitionCount) *
      (1 - Min(1.0, Occupied / 160)), 0.0, 1.0);
  if ColorCount / Count >= 0.01 then
    Quality.ColorMode := icmColor
  else if Occupied <= 2 then
    Quality.ColorMode := icmMonochrome
  else
    Quality.ColorMode := icmGrayscale;
  RepeatRatio := RepeatCount / Count;
  Quality.UpscaleRisk := EnsureRange((RepeatRatio - 0.10) / 0.60, 0.0, 1.0);
end;

function ReadByte(Stream: TStream): Byte;
begin
  if Stream.Read(Result, 1) <> 1 then raise EReadError.Create(rsTruncatedJpeg);
end;

function ReadBigEndianWord(Stream: TStream): Integer;
begin
  Result := ReadByte(Stream) shl 8;
  Result := Result or ReadByte(Stream);
end;

function DetectJpegSubsampling(const FileName: string): TChromaSubsampling;
var
  Stream: TFileStream;
  Marker, SegmentLength, Components, I, Sampling, YH, YV, MaxOtherH,
    MaxOtherV: Integer;
begin
  Result := csUnknown;
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    if (ReadByte(Stream) <> $FF) or (ReadByte(Stream) <> $D8) then Exit;
    while Stream.Position < Stream.Size - 1 do begin
      repeat Marker := ReadByte(Stream) until Marker = $FF;
      repeat Marker := ReadByte(Stream) until Marker <> $FF;
      if (Marker = $D9) or (Marker = $DA) then Exit;
      if ((Marker >= $D0) and (Marker <= $D7)) or (Marker = $01) then Continue;
      SegmentLength := ReadBigEndianWord(Stream);
      if SegmentLength < 2 then Exit;
      if Marker in [$C0, $C1, $C2, $C3, $C5, $C6, $C7, $C9, $CA, $CB, $CD, $CE, $CF] then begin
        ReadByte(Stream);
        ReadBigEndianWord(Stream); ReadBigEndianWord(Stream);
        Components := ReadByte(Stream);
        if Components = 1 then Exit(csGray);
        YH := 0; YV := 0; MaxOtherH := 1; MaxOtherV := 1;
        for I := 0 to Components - 1 do begin
          ReadByte(Stream);
          Sampling := ReadByte(Stream);
          ReadByte(Stream);
          if I = 0 then begin YH := Sampling shr 4; YV := Sampling and $F end
          else begin
            MaxOtherH := Max(MaxOtherH, Sampling shr 4);
            MaxOtherV := Max(MaxOtherV, Sampling and $F);
          end;
        end;
        if (YH = MaxOtherH) and (YV = MaxOtherV) then Exit(cs444);
        if (YH = 2 * MaxOtherH) and (YV = MaxOtherV) then Exit(cs422);
        if (YH = 2 * MaxOtherH) and (YV = 2 * MaxOtherV) then Exit(cs420);
        Exit(csOther);
      end;
      Stream.Seek(SegmentLength - 2, soCurrent);
    end;
  finally
    Stream.Free;
  end;
end;

{$IF Defined(WIN64)}
function PopCount64Asm(Value: UInt64): Integer;
asm
  POPCNT RAX, RCX
end;
{$ENDIF}

procedure FinishSignature(var Signature: TImageSignature);
var
  Gray: array[0..31, 0..31] of Double;
  Horizontal: array[0..31, 0..7] of Double;
  Coefficients, Sorted: array[0..62] of Double;
  X, Y, U, V, I, J, K, DX, DY, Channel, Sum, Offset: Integer;
  Value, Median: Double;
begin
  for Y := 0 to SampleSize - 1 do
    for X := 0 to SampleSize - 1 do
    begin
      K := (Y * SampleSize + X) * 3;
      for Channel := 0 to 2 do
      begin
        Sum := 0;
        for DY := 0 to 1 do
          for DX := 0 to 1 do
          begin
            Offset := ((Y * 2 + DY) * DetailSize + X * 2 + DX) * 3;
            Inc(Sum, Signature.DetailRGB[Offset + Channel]);
          end;
        Signature.RGB[K + Channel] := (Sum + 2) div 4;
      end;
      Gray[Y, X] := 0.299 * Signature.RGB[K] + 0.587 * Signature.RGB[K + 1] +
        0.114 * Signature.RGB[K + 2];
    end;
  DetectSignatureColorMode(Signature);
  for Y := 0 to 31 do
    for U := 0 to 7 do
    begin
      Value := 0;
      for X := 0 to 31 do
        Value := Value + Gray[Y, X] * GCosines[U, X];
      Horizontal[Y, U] := Value;
    end;
  K := 0;
  for V := 0 to 7 do
    for U := 0 to 7 do
      if (U <> 0) or (V <> 0) then
      begin
        Value := 0;
        for Y := 0 to 31 do
          Value := Value + Horizontal[Y, U] * GCosines[V, Y];
        if U = 0 then Value := Value / Sqrt(2);
        if V = 0 then Value := Value / Sqrt(2);
        if Abs(Value) < 1E-7 then Value := 0;
        Coefficients[K] := Value;
        Sorted[K] := Value;
        Inc(K);
      end;
  for I := 1 to High(Sorted) do
  begin
    Value := Sorted[I];
    J := I - 1;
    while J >= 0 do
    begin
      if Sorted[J] <= Value then Break;
      Sorted[J + 1] := Sorted[J];
      Dec(J);
    end;
    Sorted[J + 1] := Value;
  end;
  Median := Sorted[31];
  for I := 0 to High(Coefficients) do
    if Coefficients[I] > Median then
      Signature.Hash := Signature.Hash or (UInt64(1) shl I);
end;

function SignatureFromGraphic(Graphic: TGraphic): TImageSignature;
var
  Source: Vcl.Graphics.TBitmap;
  Row: PPixelRow;
  X, Y, SX, SY, K, LeftPixel, RightPixel, TopPixel, BottomPixel: Integer;
  L, R, T, B, Weight, Area, Red, Green, Blue: Double;
begin
  Result := Default(TImageSignature);
  if (Graphic = nil) or Graphic.Empty then
    raise EArgumentException.Create(rsEmptyImage);
  Source := Vcl.Graphics.TBitmap.Create;
  try
    Source.PixelFormat := pf24bit;
    Source.SetSize(Graphic.Width, Graphic.Height);
    // Source is a private 24-bit DIB owned by this worker. Canvas operations
    // apply their own short VCL synchronization; an explicit TCanvas.Lock here
    // causes severe cross-thread contention and is unnecessary for private data.
    Source.Canvas.Brush.Color := clWhite;
    Source.Canvas.FillRect(Rect(0, 0, Source.Width, Source.Height));
    Source.Canvas.Draw(0, 0, Graphic);
    // Area resampling: every source pixel contributes, even for large reductions.
    // Transparent images are composited on white. ScanLine[0] is the bottom row.
    for Y := 0 to DetailSize - 1 do
    begin
      T := Y * (Source.Height / DetailSize);
      B := (Y + 1) * (Source.Height / DetailSize);
      TopPixel := Floor(T);
      BottomPixel := Min(Source.Height - 1, Ceil(B) - 1);
      for X := 0 to DetailSize - 1 do
      begin
        L := X * (Source.Width / DetailSize);
        R := (X + 1) * (Source.Width / DetailSize);
        LeftPixel := Floor(L);
        RightPixel := Min(Source.Width - 1, Ceil(R) - 1);
        Red := 0;
        Green := 0;
        Blue := 0;
        Area := (R - L) * (B - T);
        for SY := TopPixel to BottomPixel do
        begin
          Row := Source.ScanLine[Source.Height - 1 - SY];
          for SX := LeftPixel to RightPixel do
          begin
            Weight := (Min(R, SX + 1.0) - Max(L, SX * 1.0)) *
              (Min(B, SY + 1.0) - Max(T, SY * 1.0));
            Red := Red + Row[SX].rgbtRed * Weight;
            Green := Green + Row[SX].rgbtGreen * Weight;
            Blue := Blue + Row[SX].rgbtBlue * Weight;
          end;
        end;
        K := (Y * DetailSize + X) * 3;
        Result.DetailRGB[K] := EnsureRange(Round(Red / Area), 0, 255);
        Result.DetailRGB[K + 1] := EnsureRange(Round(Green / Area), 0, 255);
        Result.DetailRGB[K + 2] := EnsureRange(Round(Blue / Area), 0, 255);
        Result.DetailGray[Y * DetailSize + X] := EnsureRange(Round(
          0.299 * Result.DetailRGB[K] + 0.587 * Result.DetailRGB[K + 1] +
          0.114 * Result.DetailRGB[K + 2]), 0, 255);
      end;
    end;
  finally
    Source.Free;
  end;
  FinishSignature(Result);
end;

function SignatureFromBGRA(const Pixels: TBytes; Width, Height,
  Stride: Integer): TImageSignature;
var
  X, Y, SX, SY, K, LeftPixel, RightPixel, TopPixel, BottomPixel,
    Alpha, PixelRed, PixelGreen, PixelBlue: Integer;
  P: PByte;
  L, R, T, B, Weight, Area, Red, Green, Blue: Double;
begin
  Result := Default(TImageSignature);
  for Y := 0 to DetailSize - 1 do
  begin
    T := Y * (Height / DetailSize);
    B := (Y + 1) * (Height / DetailSize);
    TopPixel := Floor(T);
    BottomPixel := Min(Height - 1, Ceil(B) - 1);
    for X := 0 to DetailSize - 1 do
    begin
      L := X * (Width / DetailSize);
      R := (X + 1) * (Width / DetailSize);
      LeftPixel := Floor(L);
      RightPixel := Min(Width - 1, Ceil(R) - 1);
      Red := 0;
      Green := 0;
      Blue := 0;
      Area := (R - L) * (B - T);
      for SY := TopPixel to BottomPixel do
        for SX := LeftPixel to RightPixel do
        begin
          P := @Pixels[SY * Stride + SX * 4];
          Alpha := P[3];
          PixelBlue := (P[0] * Alpha + 255 * (255 - Alpha) + 127) div 255;
          PixelGreen := (P[1] * Alpha + 255 * (255 - Alpha) + 127) div 255;
          PixelRed := (P[2] * Alpha + 255 * (255 - Alpha) + 127) div 255;
          Weight := (Min(R, SX + 1.0) - Max(L, SX * 1.0)) *
            (Min(B, SY + 1.0) - Max(T, SY * 1.0));
          Red := Red + PixelRed * Weight;
          Green := Green + PixelGreen * Weight;
          Blue := Blue + PixelBlue * Weight;
        end;
      K := (Y * DetailSize + X) * 3;
      Result.DetailRGB[K] := EnsureRange(Round(Red / Area), 0, 255);
      Result.DetailRGB[K + 1] := EnsureRange(Round(Green / Area), 0, 255);
      Result.DetailRGB[K + 2] := EnsureRange(Round(Blue / Area), 0, 255);
      Result.DetailGray[Y * DetailSize + X] := EnsureRange(Round(
        0.299 * Result.DetailRGB[K] + 0.587 * Result.DetailRGB[K + 1] +
        0.114 * Result.DetailRGB[K + 2]), 0, 255);
    end;
  end;
  FinishSignature(Result);
end;

procedure LoadImagePixels(const FileName: string; out Pixels: TBytes;
  out Width, Height: Integer; out DpiX, DpiY: Double;
  out Quality: TImageQualityMetrics);
var
  Factory: IWICImagingFactory;
  Decoder: IWICBitmapDecoder;
  Frame: IWICBitmapFrameDecode;
  Converter: IWICFormatConverter;
  W, H, Stride: UINT;
  BufferSize: UInt64;
  DecodeResult: HRESULT;
  InitResult: HRESULT;
  UninitializeCOM: Boolean;
  PixelFormat: TGUID;
  ComponentInfo: IWICComponentInfo;
  PixelInfo: IWICPixelFormatInfo;
  BitsPerPixel, ChannelCount, ColorContextCount: UINT;
begin
  Quality := Default(TImageQualityMetrics);
  InitResult := CoInitializeEx(nil, COINIT_MULTITHREADED);
  UninitializeCOM := Succeeded(InitResult);
  if Failed(InitResult) and (InitResult <> RPC_E_CHANGED_MODE) then OleCheck(InitResult);
  try
    OleCheck(CoCreateInstance(CLSID_WICImagingFactory, nil,
      CLSCTX_INPROC_SERVER, IID_IWICImagingFactory, Factory));
    DecodeResult := Factory.CreateDecoderFromFilename(PChar(FileName), GUID_NULL,
      GENERIC_READ, WICDecodeMetadataCacheOnDemand, Decoder);
    if Cardinal(DecodeResult) = WINCODEC_ERR_COMPONENTNOTFOUND then
      raise EInvalidGraphic.CreateFmt(rsImageDecoderUnavailable,
        [ExtractFileExt(FileName)]);
    OleCheck(DecodeResult);
    // Always use frame zero, for both comparison and preview.
    OleCheck(Decoder.GetFrame(0, Frame));
    OleCheck(Frame.GetSize(W, H));
    DpiX := 96;
    DpiY := 96;
    if Failed(Frame.GetResolution(DpiX, DpiY)) then
    begin
      DpiX := 96;
      DpiY := 96;
    end;
    if (W = 0) or (H = 0) or (W > MaxInt div 4) then
      raise EInvalidGraphic.Create(rsInvalidImageDimensions);
    Stride := W * 4;
    BufferSize := UInt64(Stride) * H;
    if BufferSize > MaxInt then
      raise EInvalidGraphic.Create(rsImageTooLarge);
    OleCheck(Factory.CreateFormatConverter(Converter));
    OleCheck(Converter.Initialize(Frame, GUID_WICPixelFormat32bppBGRA,
      WICBitmapDitherTypeNone, nil, 0, WICBitmapPaletteTypeCustom));
    SetLength(Pixels, NativeInt(BufferSize));
    OleCheck(Converter.CopyPixels(nil, Stride, Length(Pixels), @Pixels[0]));
    Width := W;
    Height := H;


    if Succeeded(Frame.GetPixelFormat(PixelFormat)) and
      Succeeded(Factory.CreateComponentInfo(PixelFormat, ComponentInfo)) and
      Supports(ComponentInfo, IWICPixelFormatInfo, PixelInfo) then begin
      BitsPerPixel := 0; ChannelCount := 0;
      if Succeeded(PixelInfo.GetBitsPerPixel(BitsPerPixel)) and
        Succeeded(PixelInfo.GetChannelCount(ChannelCount)) and (ChannelCount > 0) then
        Quality.BitDepth := Ceil(BitsPerPixel / ChannelCount);
    end;
    ColorContextCount := 0;
    if Succeeded(Frame.GetColorContexts(0, nil, ColorContextCount)) then
      Quality.HasColorProfile := ColorContextCount > 0;
    if SameText(ExtractFileExt(FileName), '.jpg') or
      SameText(ExtractFileExt(FileName), '.jpeg') then
      try
        Quality.ChromaSubsampling := DetectJpegSubsampling(FileName);
      except
        Quality.ChromaSubsampling := csUnknown;
      end
    else
      Quality.ChromaSubsampling := csNotApplicable;
  finally
    PixelInfo := nil;
    ComponentInfo := nil;
    Converter := nil;
    Frame := nil;
    Decoder := nil;
    Factory := nil;
    if UninitializeCOM then CoUninitialize;
  end;
end;

function LoadSignature(const FileName: string; out Width, Height: Integer;
  out DpiX, DpiY: Double): TImageSignature;
var
  Pixels: TBytes;
  Metadata: TImageQualityMetrics;
begin
  LoadImagePixels(FileName, Pixels, Width, Height, DpiX, DpiY, Metadata);
  Result := SignatureFromBGRA(Pixels, Width, Height, Width * 4);
  AnalyzePixels(Pixels, Width, Height, Width * 4, Result.Quality);
  if Metadata.BitDepth > 0 then
    Result.Quality.BitDepth := Metadata.BitDepth;
  Result.Quality.HasColorProfile := Metadata.HasColorProfile;
  Result.Quality.ChromaSubsampling := Metadata.ChromaSubsampling;
end;

procedure LoadImagePreview(const FileName: string; Picture: TPicture);
var
  Pixels: TBytes;
  Width, Height, X, Y, Offset, Alpha: Integer;
  DpiX, DpiY: Double;
  Metadata: TImageQualityMetrics;
  Bitmap: Vcl.Graphics.TBitmap;
  Row: PPixelRow;
begin
  LoadImagePixels(FileName, Pixels, Width, Height, DpiX, DpiY, Metadata);
  Bitmap := Vcl.Graphics.TBitmap.Create;
  try
    Bitmap.PixelFormat := pf24bit;
    Bitmap.SetSize(Width, Height);
    for Y := 0 to Height - 1 do
    begin
      // VCL ScanLine already maps top-down row indices to the DIB layout.
      Row := Bitmap.ScanLine[Y];
      Offset := Y * Width * 4;
      for X := 0 to Width - 1 do
      begin
        // Match the white background used for transparent comparison pixels.
        Alpha := Pixels[Offset + 3];
        Row[X].rgbtBlue := (Pixels[Offset] * Alpha +
          255 * (255 - Alpha) + 127) div 255;
        Row[X].rgbtGreen := (Pixels[Offset + 1] * Alpha +
          255 * (255 - Alpha) + 127) div 255;
        Row[X].rgbtRed := (Pixels[Offset + 2] * Alpha +
          255 * (255 - Alpha) + 127) div 255;
        Inc(Offset, 4);
      end;
    end;
    Picture.Assign(Bitmap);
  finally
    Bitmap.Free;
  end;
end;

function LoadSignature(const FileName: string): TImageSignature;
var Width, Height: Integer; DpiX, DpiY: Double;
begin
  Result := LoadSignature(FileName, Width, Height, DpiX, DpiY);
end;

function LoadSignature(const FileName: string; out Width,
  Height: Integer): TImageSignature;
var DpiX, DpiY: Double;
begin
  Result := LoadSignature(FileName, Width, Height, DpiX, DpiY);
end;

function HashDistance(A, B: UInt64): Integer;
var
  Bits: UInt64;
begin
  Bits := A xor B;
{$IF Defined(WIN64)}
  if GPopCntAvailable then
  begin
    Result := PopCount64Asm(Bits);
    Exit;
  end;
{$ENDIF}
  Result := 0;
  while Bits <> 0 do
  begin
    Bits := Bits and (Bits - 1);
    Inc(Result);
  end;
end;

function PixelError(const A, B: TImageSignature): Double;
var
  I, Delta: Integer;
  Sum: Double;
begin
  Sum := 0;
  for I := 0 to High(A.RGB) do
  begin
    Delta := Integer(A.RGB[I]) - Integer(B.RGB[I]);
    Sum := Sum + Delta * Delta;
  end;
  Result := Sqrt(Sum / Length(A.RGB)) / 255;
end;

// SSIM formula on non-overlapping 8x8 luminance blocks with uniform weights.
// This is not the reference Gaussian-window or multiscale SSIM implementation.
procedure StructuralMetrics(const A, B: TImageSignature; out Metrics: TComparison);
const
  C1 = 6.5025;
  C2 = 58.5225;
var
  BX, BY, X, Y, K, C, Delta: Integer;
  SA, SB, SAA, SBB, SAB, VA, VB, Covariance, MA, MB: Double;
  LA, LB, Score, BlockError, TotalError: Double;
begin
  Metrics := Default(TComparison);
  Metrics.Distance := HashDistance(A.Hash, B.Hash);
  Metrics.WorstStructural := 1;
  TotalError := 0;
  for BY := 0 to 7 do
    for BX := 0 to 7 do
    begin
      SA := 0; SB := 0; SAA := 0; SBB := 0; SAB := 0; BlockError := 0;
      for Y := BY * 8 to BY * 8 + 7 do
        for X := BX * 8 to BX * 8 + 7 do
        begin
          K := (Y * DetailSize + X) * 3;
          LA := A.DetailGray[Y * DetailSize + X];
          LB := B.DetailGray[Y * DetailSize + X];
          SA := SA + LA; SB := SB + LB;
          SAA := SAA + LA * LA; SBB := SBB + LB * LB; SAB := SAB + LA * LB;
          for C := 0 to 2 do
          begin
            Delta := Integer(A.DetailRGB[K+C]) - Integer(B.DetailRGB[K+C]);
            BlockError := BlockError + Delta * Delta;
          end;
        end;
      MA := SA / 64; MB := SB / 64;
      VA := Max(0, (SAA - SA * SA / 64) / 63);
      VB := Max(0, (SBB - SB * SB / 64) / 63);
      Covariance := (SAB - SA * SB / 64) / 63;
      Score := EnsureRange(((2 * MA * MB + C1) * (2 * Covariance + C2)) /
        ((MA * MA + MB * MB + C1) * (VA + VB + C2)), -1.0, 1.0);
      Metrics.Structural := Metrics.Structural + Score;
      Metrics.WorstStructural := Min(Metrics.WorstStructural, Score);
      Metrics.WorstRGB := Max(Metrics.WorstRGB, Sqrt(BlockError / (64 * 3)) / 255);
      TotalError := TotalError + BlockError;
    end;
  Metrics.Structural := Metrics.Structural / 64;
  Metrics.RGBError := Sqrt(TotalError / Length(A.DetailRGB)) / 255;
end;

function CompareSignatures(const A, B: TImageSignature; MaxDistance: Integer;
  MaxRGBError: Double; out Metrics: TComparison): Boolean;
begin
  Metrics := Default(TComparison);
  Metrics.Distance := HashDistance(A.Hash, B.Hash);
  Result := False;
  if Metrics.Distance > MaxDistance then Exit;
  if PixelError(A, B) > MaxRGBError then Exit;
  StructuralMetrics(A, B, Metrics);
  Result := (Metrics.RGBError <= MaxRGBError) and
    (Metrics.Structural >= MinStructuralSimilarity) and
    (Metrics.WorstStructural >= MinLocalSimilarity) and
    (Metrics.WorstRGB <= MaxLocalRGBError);
end;

procedure InitializeCoreTables;
var U, X: Integer;
begin
  for U := 0 to 7 do
    for X := 0 to 31 do
      GCosines[U, X] := Cos((2 * X + 1) * U * Pi / 64);
{$IF Defined(WIN64)}
  GPopCntAvailable := IsProcessorFeaturePresent(PF_POPCNT_INSTRUCTION_AVAILABLE);
{$ELSE}
  GPopCntAvailable := False;
{$ENDIF}
end;

initialization
  InitializeCoreTables;
end.
