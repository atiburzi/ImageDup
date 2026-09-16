program ImageDup.CompareTest;
{$APPTYPE CONSOLE}
uses System.SysUtils, ImageDup.Core in 'ImageDup.Core.pas';
var A, B: TImageSignature; M: TComparison; Accepted: Boolean;
begin
  try
    A := LoadSignature(ParamStr(1));
    B := LoadSignature(ParamStr(2));
    StructuralMetrics(A, B, M);
    Writeln('Hash distance: ', M.Distance);
    Writeln('Old RGB32: ', PixelError(A,B):0:6);
    Writeln('RGB64: ', M.RGBError:0:6);
    Writeln('SSIM mean: ', M.Structural:0:6);
    Writeln('SSIM worst: ', M.WorstStructural:0:6);
    Writeln('RGB worst: ', M.WorstRGB:0:6);
    Accepted := CompareSignatures(A,B,1,0.08,M);
    Writeln('Accepted distance 1: ', Accepted);
  except on E: Exception do begin Writeln(E.Message); ExitCode := 1 end end;
end.
