<#
.SYNOPSIS
  Generates the Open Graph images for matacic.net (1200x630) with .NET System.Drawing.
  Run once, commit the PNGs. Nothing here runs during `hugo` builds.

  Outputs
    static/og-default.png  - site-wide fallback card (wordmark, name, role, tagline)
    assets/og-base.png     - same header, empty title area; Hugo's images.Text draws the
                             article title on it at build time (see layouts/_partials/seo.html)

  Non-ASCII characters are written as [char] code points on purpose: Windows PowerShell 5.1
  reads BOM-less scripts as ANSI, which would otherwise garble them.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts/make-og.ps1
#>
param(
  [string]$Root = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$fontPath = Join-Path $Root 'assets\fonts\IBMPlexMono-Medium.ttf'
$iconPath = Join-Path $Root 'static\icon-server.png'
if (-not (Test-Path $fontPath)) { throw "Font not found: $fontPath" }
if (-not (Test-Path $iconPath)) { throw "Icon not found: $iconPath" }

$fonts = New-Object System.Drawing.Text.PrivateFontCollection
$fonts.AddFontFile($fontPath)
$family = $fonts.Families[0]

# Characters outside ASCII
$dot   = [string][char]0x00B7                       # middle dot
$name      = 'Ivan Mata' + [char]0x010D + 'i' + [char]0x0107      # Ivan Matacic with c-caron, c-acute
$nameUpper = 'IVAN MATA' + [char]0x010C + 'I' + [char]0x0106      # uppercase variant (PowerShell variables are case-insensitive, hence the distinct name)

function Color([string]$hex) { [System.Drawing.ColorTranslator]::FromHtml($hex) }
function Brush([string]$hex) { New-Object System.Drawing.SolidBrush (Color $hex) }
function Font([int]$px) { New-Object System.Drawing.Font -ArgumentList @($family, [single]$px, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel) }

# Palette (dark theme tokens)
$bg = Color '#0c0f14'; $border = Color '#232a34'
$ink = Brush '#e8edf3'; $muted = Brush '#9aa5b1'; $faint = Brush '#6b7684'; $amber = Brush '#f59e0b'

$fmt = [System.Drawing.StringFormat]::GenericTypographic

function New-Card([string]$OutPath, [scriptblock]$Body) {
  $bmp = New-Object System.Drawing.Bitmap 1200, 630
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
  $g.Clear($bg)

  # hairline frame
  $pen = New-Object System.Drawing.Pen ($border, 2)
  $g.DrawRectangle($pen, 1, 1, 1197, 627)

  # header: icon + wordmark
  $icon = [System.Drawing.Image]::FromFile($iconPath)
  $g.DrawImage($icon, (New-Object System.Drawing.Rectangle 80, 72, 84, 84))
  $icon.Dispose()
  $big = Font 64
  $g.DrawString('matacic', $big, $ink, 188, 80, $fmt)
  $w = $g.MeasureString('matacic', $big, 2000, $fmt).Width
  $g.DrawString('.net', $big, $amber, 188 + $w, 80, $fmt)

  # footer rule
  $rule = New-Object System.Drawing.Pen ($border, 1)
  $g.DrawLine($rule, 80, 540, 1120, 540)

  & $Body $g

  $dir = Split-Path $OutPath -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $bmp.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose()
  Write-Output "wrote $OutPath"
}

# 1) Site-wide default card
New-Card (Join-Path $Root 'static\og-default.png') {
  param($g)
  $g.DrawString('SYSTEMS & INFRASTRUCTURE', (Font 22), $amber, 80, 228, $fmt)
  $g.DrawString($name, (Font 60), $ink, 80, 268, $fmt)
  $g.DrawString("Virtualization $dot storage $dot backup $dot networking.", (Font 27), $muted, 80, 372, $fmt)
  $g.DrawString('Fixes, failures and homelab experiments, written down.', (Font 27), $muted, 80, 416, $fmt)
  $g.DrawString("Zagreb, HR $dot since 2019", (Font 20), $faint, 80, 560, $fmt)
}

# 2) Base for per-article cards: title area (y 296-520) is left empty for images.Text
New-Card (Join-Path $Root 'assets\og-base.png') {
  param($g)
  $g.DrawString("WRITING $dot $nameUpper", (Font 22), $amber, 80, 228, $fmt)
  $g.DrawString('matacic.net', (Font 20), $faint, 80, 560, $fmt)
}
