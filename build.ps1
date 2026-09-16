param(
    [string]$DelphiRoot = 'C:\Program Files (x86)\Embarcadero\Studio\37.0',
    [string]$VirtualTreeRoot = 'H:\Documenti\Embarcadero\Studio\37.0\CatalogRepository\VirtualTreeview_by_JamSoftware-13\8.3\Source'
)
$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    New-Item -ItemType Directory -Force -Path build | Out-Null
    foreach ($project in @('ImageDup.dpr', 'ImageDup.CLI.dpr')) {
        $unitPath = (Join-Path $DelphiRoot 'lib\win64\release') + ';' + $VirtualTreeRoot
        & (Join-Path $DelphiRoot 'bin\dcc64.exe') '-B' '-Q' '-Ebuild' '-NUbuild' ('-U' + $unitPath) $project
        if ($LASTEXITCODE -ne 0) { throw ('Compilazione fallita: ' + $project) }
    }
} finally { Pop-Location }
