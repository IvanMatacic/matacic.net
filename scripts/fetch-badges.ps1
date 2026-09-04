<#
.SYNOPSIS
  Downloads Credly badge artwork for the certifications in data/certifications.yaml.

  For every item without an `image:` line (or all items with -Force) it opens the badge's public
  Credly page, reads the og:image URL, derives the square original from it, downloads the 340x340
  rendition, scales it to -Size pixels (default 132 = 3x the 44 px slot on /about/) with a
  transparent background and saves static/badges/<slug>.png.

  It does NOT edit the YAML. It prints the `image:` lines to add, so you stay in control.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts/fetch-badges.ps1
  powershell -ExecutionPolicy Bypass -File scripts/fetch-badges.ps1 -Force   # re-download everything
#>
param(
  [string]$Root = (Split-Path $PSScriptRoot -Parent),
  [int]$Size = 132,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Drawing

$ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0 Safari/537.36'
$yamlPath = Join-Path $Root 'data\certifications.yaml'
$outDir = Join-Path $Root 'static\badges'
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }

$yaml = Get-Content $yamlPath -Raw -Encoding UTF8
# name / year / id, followed by an optional *uncommented* image line
$rx = '- name: "(?<name>[^"]+)"\s*\r?\n\s*year: (?<year>\d+)\s*\r?\n\s*id: "(?<id>[0-9a-f-]{36})"(\s*\r?\n[ \t]*image: "(?<image>[^"]+)")?'
$items = [regex]::Matches($yaml, $rx)
"items in YAML: $($items.Count)"

function Slug([string]$s) {
  $t = $s.ToLowerInvariant()
  $t = [regex]::Replace($t, '[^a-z0-9]+', '-')
  return $t.Trim('-')
}

$toAdd = @()
foreach ($m in $items) {
  $id = $m.Groups['id'].Value
  $name = $m.Groups['name'].Value
  $existing = $m.Groups['image'].Value
  if ($existing -and -not $Force) { "skip  $name (already has image: $existing)"; continue }

  $file = (Slug $name) + '.png'
  $dest = Join-Path $outDir $file
  $tmp = $null; $src = $null; $bmp = $null; $g = $null
  try {
    $page = Invoke-WebRequest -Uri "https://www.credly.com/badges/$id/public_url" -UseBasicParsing `
      -Headers @{ 'User-Agent' = $ua; 'Accept' = 'text/html' } -TimeoutSec 30
    $og = [regex]::Match($page.Content, '<meta property="og:image" content="(?<u>https://images\.credly\.com/images/[^"]+)"').Groups['u'].Value
    if (-not $og) { throw 'no og:image on the public badge page' }
    # og:image is the LinkedIn banner; the square badge is the same file without the thumb prefix
    $square = $og -replace '/images/([0-9a-f-]+)/linkedin_thumb_', '/size/340x340/images/$1/'

    $tmp = [IO.Path]::GetTempFileName()
    Invoke-WebRequest -Uri $square -OutFile $tmp -UseBasicParsing -Headers @{ 'User-Agent' = $ua } -TimeoutSec 60
    $src = [System.Drawing.Image]::FromFile($tmp)

    $bmp = New-Object System.Drawing.Bitmap -ArgumentList @($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)
    $scale = [Math]::Min($Size / $src.Width, $Size / $src.Height)
    $w = [int][Math]::Round($src.Width * $scale); $h = [int][Math]::Round($src.Height * $scale)
    $g.DrawImage($src, [int](($Size - $w) / 2), [int](($Size - $h) / 2), $w, $h)
    $bmp.Save($dest, [System.Drawing.Imaging.ImageFormat]::Png)

    "ok    $name -> badges/$file ($($src.Width)x$($src.Height) -> ${Size}x${Size}, $((Get-Item $dest).Length) bytes)"
    $toAdd += [pscustomobject]@{ name = $name; image = "badges/$file" }
  } catch {
    "FAIL  $name : $($_.Exception.Message)"
  } finally {
    if ($g) { $g.Dispose() }; if ($bmp) { $bmp.Dispose() }; if ($src) { $src.Dispose() }
    if ($tmp -and (Test-Path $tmp)) { [IO.File]::Delete($tmp) }
  }
  Start-Sleep -Milliseconds 400
}

if ($toAdd.Count) {
  ""
  "Add these lines under the matching items in data/certifications.yaml (same indent as `id:`):"
  $toAdd | ForEach-Object { "  {0,-60} image: `"{1}`"" -f ($_.name + ':'), $_.image }
}
