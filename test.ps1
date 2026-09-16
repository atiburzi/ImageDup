$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$exe = Join-Path $PSScriptRoot 'build\ImageDup.CLI.exe'
$testRoot = Join-Path $PSScriptRoot ('build\test-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot | Out-Null
$nested = Join-Path $testRoot 'nested'
New-Item -ItemType Directory -Path $nested | Out-Null
function Require($Condition, $Message) { if (!$Condition) { throw $Message } }
function Make-Pattern([int]$Size, [string]$Path, [bool]$Different) {
    $bmp = New-Object System.Drawing.Bitmap $Size,$Size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    try {
        $g.Clear([System.Drawing.Color]::White)
        if ($Different) {
            $g.FillRectangle([System.Drawing.Brushes]::DarkGreen, 0, 0, $Size, ($Size / 2))
            $g.FillEllipse([System.Drawing.Brushes]::Black, ($Size / 2), ($Size / 2), ($Size / 2), ($Size / 2))
        } else {
            $g.FillRectangle([System.Drawing.Brushes]::Navy, ($Size / 8), ($Size / 4), ($Size / 4), ($Size / 2))
            $g.FillEllipse([System.Drawing.Brushes]::OrangeRed, ($Size / 2), ($Size / 8), ($Size / 4), ($Size / 2))
        }
        $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally { $g.Dispose(); $bmp.Dispose() }
}
Make-Pattern 256 (Join-Path $testRoot 'original.png') $false
Make-Pattern 512 (Join-Path $nested 'resized.png') $false
Make-Pattern 256 (Join-Path $testRoot 'different.png') $true
Copy-Item -LiteralPath (Join-Path $testRoot 'original.png') -Destination (Join-Path $testRoot 'copy.png')
$bmp = [System.Drawing.Bitmap]::FromFile((Join-Path $testRoot 'original.png'))
try {
    $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object MimeType -eq 'image/jpeg'
    $parameters = New-Object System.Drawing.Imaging.EncoderParameters 1
    $parameters.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality), ([long]35)
    try { $bmp.Save((Join-Path $testRoot 'compressed.jpg'), $codec, $parameters) }
    finally { $parameters.Dispose() }
} finally { $bmp.Dispose() }
foreach ($name in @('Red','Blue')) {
    $bmp = New-Object System.Drawing.Bitmap 32,32
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    try { $g.Clear([System.Drawing.Color]::FromName($name)); $bmp.Save((Join-Path $testRoot ($name + '.bmp')), [System.Drawing.Imaging.ImageFormat]::Bmp) }
    finally { $g.Dispose(); $bmp.Dispose() }
}
$report = Join-Path $testRoot 'matches.csv'
& $exe $testRoot --recursive --csv $report
Require ($LASTEXITCODE -eq 0) 'Scansione fallita'
$rows = @(Import-Csv -LiteralPath $report)
Require ($rows.Count -eq 6) ('Attese 6 coppie tra 4 varianti, ottenute ' + $rows.Count)
foreach ($row in $rows) {
    Require ($row.file_a -notmatch '(different|Red|Blue)\.(png|bmp)$') 'Falso positivo A'
    Require ($row.file_b -notmatch '(different|Red|Blue)\.(png|bmp)$') 'Falso positivo B'
}
$before = (Get-FileHash -LiteralPath $report).Hash
& $exe $testRoot --csv $report
Require ($LASTEXITCODE -eq 1) 'Il report esistente deve essere rifiutato'
Require ((Get-FileHash -LiteralPath $report).Hash -eq $before) 'Report modificato'
$flat = Join-Path $testRoot 'flat.csv'
& $exe $testRoot --csv $flat
Require ($LASTEXITCODE -eq 0) 'Scansione non ricorsiva fallita'
Require (@(Import-Csv -LiteralPath $flat).Count -eq 3) 'La scansione non ricorsiva ha incluso sottocartelle'
& $exe $testRoot --distance 64
Require ($LASTEXITCODE -eq 1) 'Soglia non valida accettata'
Set-Content -LiteralPath (Join-Path $testRoot 'broken.jpg') -Value 'not an image'
& $exe $testRoot
Require ($LASTEXITCODE -eq 2) 'File corrotto non segnalato con codice 2'
Write-Host ('PASS: ricampionamento, JPEG, copie, falsi positivi, ricorsione, CSV, argomenti e file corrotti. Artefatti: ' + $testRoot)
$global:LASTEXITCODE = 0
