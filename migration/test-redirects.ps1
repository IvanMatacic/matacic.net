<#
.SYNOPSIS
  Checks the live 301s from mata.com.hr against redirects-from-mata.csv.
  Every old URL (and its non-www / http variant) must answer 301 with the mapped target,
  and an unknown path must land on the home page. Read-only; exits 1 on any mismatch.
#>
$ErrorActionPreference = 'Stop'
$fail = 0
function Probe([string]$url, [string]$want) {
  $r = Invoke-WebRequest $url -Method Head -MaximumRedirection 0 -SkipHttpErrorCheck -TimeoutSec 15 -ErrorAction SilentlyContinue  # a 3xx with redirects off is reported as an error
  $loc = [string]$r.Headers.Location
  if ($r.StatusCode -eq 301 -and $loc -eq $want) { "  PASS  $url" }
  else { "  FAIL  $url -> $($r.StatusCode) $loc (want $want)"; $script:fail++ }
}

foreach ($row in Import-Csv (Join-Path $PSScriptRoot 'redirects-from-mata.csv')) {
  Probe $row.old_url $row.new_url
}
Probe 'http://mata.com.hr/prtg/how-to-renew-lets-encrypt-certificate-for-prtg/' 'https://matacic.net/notes/prtg-lets-encrypt-renewal/'
Probe 'https://mata.com.hr/tag/prtg' 'https://matacic.net/tags/prtg/'
Probe 'https://www.mata.com.hr/no-such-page/' 'https://matacic.net/'
Probe 'https://www.mata.com.hr/wp-admin/' 'https://matacic.net/'

"`nRESULT: $(if ($fail) { "$fail check(s) failed" } else { 'all redirects OK' })"
exit [int]($fail -gt 0)
