<#
.SYNOPSIS
  Regenerate static/cv.pdf from the About page. Run after editing content/about.md.

.DESCRIPTION
  GitHub Pages only serves the file; it cannot build it, because the Actions runner
  has no Edge and no way to run this. So the PDF is a committed artifact: regenerate
  it here and commit it alongside the content change. verify.ps1 fails if it is stale.

  A short-lived `hugo server` supplies the page over http so the fingerprinted CSS
  (integrity + crossorigin) loads exactly as it does in production. Printing the file
  from ./public directly does not work: those pages reference https://matacic.net/.

  Known limitation: headings print in Segoe UI, not IBM Plex Sans. Google Fonts serves
  Plex Sans as a variable font (the @font-face rules carry font-stretch: 100%) and
  Chromium does not embed variable webfonts in print-to-PDF, so it substitutes a system
  face. Plex Mono and Plex Serif are static and do embed. The fix, if it ever matters,
  is to self-host a static Plex Sans in assets/fonts and drop it from the Google URL.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts/build-cv-pdf.ps1
#>
param(
  [string]$Root = (Split-Path $PSScriptRoot -Parent),
  [int]$Port = 1414,
  [string]$Edge
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if (-not $Edge) {
  $candidates = @(
    "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
    "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"
  )
  $Edge = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
}
if (-not $Edge) { throw "Edge not found. Pass -Edge <path to msedge.exe>." }

$out = Join-Path $Root 'static\cv.pdf'
$url = "http://127.0.0.1:$Port/about/"

# Keep the production baseURL so the printed contact line reads matacic.net, not localhost.
$hugoArgs = @(
  'server',
  '--port', $Port,
  '--baseURL', 'https://matacic.net/',
  '--appendPort=false',
  '--disableLiveReload',
  '--renderToMemory'
)

$log = Join-Path $env:TEMP "hugo-cv-$Port.log"
Write-Host "Starting hugo server on port $Port ..."
$srv = Start-Process -FilePath 'hugo' -ArgumentList $hugoArgs -WorkingDirectory $Root -PassThru -WindowStyle Hidden `
  -RedirectStandardOutput $log -RedirectStandardError "$log.err"

try {
  # Probe the socket, not HTTP: no proxy rules, no IPv6/localhost ambiguity.
  $ready = $false
  foreach ($i in 1..60) {
    if ($srv.HasExited) {
      Get-Content $log, "$log.err" -ErrorAction SilentlyContinue | Write-Host
      throw "hugo server exited early (code $($srv.ExitCode)). Is port $Port already in use?"
    }
    $client = New-Object Net.Sockets.TcpClient
    try { $client.Connect('127.0.0.1', $Port); $ready = $client.Connected } catch { } finally { $client.Close() }
    if ($ready) { break }
    Start-Sleep -Milliseconds 500
  }
  if (-not $ready) {
    Get-Content $log, "$log.err" -ErrorAction SilentlyContinue | Write-Host
    throw "hugo server did not open port $Port within 30s."
  }

  # A persistent profile means the second pass serves the Google Fonts faces and the 13
  # badge images from Edge's HTTP cache. Without it the virtual-time budget can expire
  # with IBM Plex Sans still in flight and the headings print in the fallback face.
  $profile = Join-Path $env:TEMP 'matacic-cv-edge-profile'
  $edgeArgs = @(
    '--headless=new',
    '--disable-gpu',
    '--no-pdf-header-footer',
    '--print-to-pdf-no-header',
    '--run-all-compositor-stages-before-draw',
    '--virtual-time-budget=30000',
    "--user-data-dir=$profile",
    "--print-to-pdf=$out",
    $url
  )

  foreach ($pass in 1..2) {
    Write-Host "Printing $url (pass $pass of 2) ..."
    $print = Start-Process -FilePath $Edge -ArgumentList $edgeArgs -Wait -PassThru -WindowStyle Hidden
    if ($print.ExitCode -ne 0) { throw "Edge exited with code $($print.ExitCode)." }
  }
}
finally {
  if (-not $srv.HasExited) { Stop-Process -Id $srv.Id -Force }
}

if (-not (Test-Path $out)) { throw "Edge reported success but $out is missing." }
$kb = [math]::Round((Get-Item $out).Length / 1KB, 1)
Write-Host "Wrote static/cv.pdf ($kb KB). Rebuild the site so it lands in ./public, then commit it."
