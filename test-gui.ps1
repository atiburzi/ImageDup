param(
    [string]$DelphiRoot = 'C:\Program Files (x86)\Embarcadero\Studio\37.0',
    [string]$ReportedPairFolder = '',
    [string]$VirtualTreeRoot = 'H:\Documenti\Embarcadero\Studio\37.0\CatalogRepository\VirtualTreeview_by_JamSoftware-13\8.3\Source'
)
$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    & .\build.ps1 -DelphiRoot $DelphiRoot -VirtualTreeRoot $VirtualTreeRoot
    & .\test.ps1
    if ($LASTEXITCODE -ne 0) { throw 'Test CLI falliti' }
    $fixture = Get-ChildItem -LiteralPath build -Directory -Filter 'test-*' |
        Sort-Object CreationTime -Descending | Select-Object -First 1
    $unitPath = (Join-Path $DelphiRoot 'lib\win64\release') + ';' + $VirtualTreeRoot
    & (Join-Path $DelphiRoot 'bin\dcc64.exe') '-B' '-Q' '-Ebuild' '-NUbuild' '-$R+' '-$Q+' ('-U' + $unitPath) ImageDup.GuiTests.dpr
    if ($LASTEXITCODE -ne 0) { throw 'Compilazione test GUI fallita' }
    & (Join-Path $DelphiRoot 'bin\dcc64.exe') '-B' '-Q' '-Ebuild' '-NUbuild' '-$R+' '-$Q+' ('-U' + (Join-Path $DelphiRoot 'lib\win64\release')) ImageDup.CoreTests.dpr
    if ($LASTEXITCODE -ne 0) { throw 'Compilazione test motore fallita' }
    & .\build\ImageDup.CoreTests.exe
    if ($LASTEXITCODE -ne 0) { throw 'Test motore falliti' }
    if ($ReportedPairFolder) {
        & .\build\ImageDup.GuiTests.exe $fixture.FullName $ReportedPairFolder
    } else {
        & .\build\ImageDup.GuiTests.exe $fixture.FullName
    }
    if ($LASTEXITCODE -ne 0) { throw 'Test GUI falliti' }
} finally { Pop-Location }
