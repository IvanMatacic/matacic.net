<#
.SYNOPSIS
  Acceptance checks for the built site (./public). Run after `hugo --gc --minify --panicOnWarning`.
  Read-only: prints findings, exits 1 if any hard check fails.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts/verify.ps1
#>
param([string]$Root = (Split-Path $PSScriptRoot -Parent))

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$pub = Join-Path $Root 'public'
if (-not (Test-Path $pub)) { throw "No ./public - build first." }
$fail = 0
function Check([bool]$ok, [string]$msg) { if ($ok) { "  PASS  $msg" } else { "  FAIL  $msg"; $script:fail++ } }
function Html([string]$rel) { Get-Content -Encoding UTF8 (Join-Path $pub $rel) -Raw }
function JsonLd([string]$rel) {
  $m = [regex]::Match((Html $rel), '<script type="?application/ld\+json"?>(.*?)</script>', 'Singleline')
  if (-not $m.Success) { return $null }
  $m.Groups[1].Value | ConvertFrom-Json
}

"== robots.txt"
$robots = Get-Content -Encoding UTF8 (Join-Path $pub 'robots.txt') -Raw
$robots
Check ($robots -match 'Sitemap: https://matacic\.net/sitemap\.xml') 'robots.txt has absolute Sitemap line'
Check ($robots -match 'User-agent: GPTBot' -and $robots -match 'User-agent: ClaudeBot') 'robots.txt has AI crawler block'

"`n== llms.txt (first 20 lines)"
Get-Content -Encoding UTF8 (Join-Path $pub 'llms.txt') -TotalCount 20
$llms = Get-Content -Encoding UTF8 (Join-Path $pub 'llms.txt') -Raw
$writing = (Get-ChildItem (Join-Path $pub 'writing') -Directory).Count
$notes   = (Get-ChildItem (Join-Path $pub 'notes') -Directory).Count
Check (([regex]::Matches($llms, '\]\(https://matacic\.net/writing/')).Count -eq $writing) "llms.txt lists all $writing articles with absolute URLs"
Check (([regex]::Matches($llms, '\]\(https://matacic\.net/notes/')).Count -eq $notes) "llms.txt lists all $notes notes"
Check (-not ($llms -match '/search/')) 'llms.txt does not list /search/'

"`n== sitemap.xml"
$locs = Select-Xml -Path (Join-Path $pub 'sitemap.xml') -XPath "//*[local-name()='loc']" | ForEach-Object { $_.Node.InnerText }
$locs
Check (-not ($locs -contains 'https://matacic.net/search/')) 'sitemap excludes /search/'
foreach ($must in 'https://matacic.net/', 'https://matacic.net/writing/', 'https://matacic.net/notes/', 'https://matacic.net/homelab/', 'https://matacic.net/about/', 'https://matacic.net/topics/homelab/') {
  Check ($locs -contains $must) "sitemap lists $must"
}

"`n== bundle sizes"
Get-ChildItem (Join-Path $pub 'js') -Filter '*.js' | ForEach-Object { "  $($_.Name)  $($_.Length) bytes"; Check ($_.Length -lt 4096) 'JS bundle under 4 KB' }
Get-ChildItem (Join-Path $pub 'css') -Filter '*.css' | ForEach-Object { "  $($_.Name)  $($_.Length) bytes" }
$homeHtml = Html 'index.html'
Check ($homeHtml -match 'integrity="?sha') 'CSS/JS linked with SRI integrity'

"`n== JSON-LD"
$about = JsonLd 'about/index.html'
Check ($null -ne $about) 'about JSON-LD parses'
Check ($about.'@type' -eq 'Person') 'about JSON-LD is Person'
Check ($about.hasCredential.Count -eq 13) "about has 13 hasCredential (got $($about.hasCredential.Count))"
Check ($about.hasCredential[0].recognizedBy.'@type' -eq 'Organization') 'credential recognizedBy is Organization'
$art = JsonLd 'writing/lets-encrypt-certificate-for-prtg/index.html'
Check ($art.'@type' -eq 'BlogPosting') 'article JSON-LD is BlogPosting'
Check ($art.image -match '^https://matacic\.net/.+\.png$') "article JSON-LD image is absolute ($($art.image))"
$note = JsonLd 'notes/journalctl-single-unit-and-boot/index.html'
Check ($note.'@type' -eq 'BlogPosting') 'note JSON-LD is BlogPosting'
$hm = JsonLd 'index.html'
Check ($hm.'@type' -eq 'WebSite' -and $hm.author.'@type' -eq 'Person') 'home JSON-LD is WebSite with Person author'

"`n== certifications"
$aboutHtml = Html 'about/index.html'
$credly = ([regex]::Matches($aboutHtml, 'href="?https://www\.credly\.com/badges/[0-9a-f-]{36}/public_url"?')).Count
Check ($credly -eq 13) "13 Credly links on /about/ (got $credly)"
$credlyLd = ([regex]::Matches($aboutHtml, '"url":"https://www\.credly\.com/badges/[0-9a-f-]{36}/public_url"')).Count
Check ($credlyLd -eq 13) "13 Credly URLs in the Person JSON-LD (got $credlyLd)"
$newtab = ([regex]::Matches($aboutHtml, 'public_url"? target="?_blank"? rel="?noopener"?')).Count
Check ($newtab -eq 13) "13 Credly links open in a new tab with rel=noopener (got $newtab)"
Check ($aboutHtml -match 'href="?https://www\.linkedin\.com/[^ >]+ target="?_blank"? rel="?me noopener"?') 'LinkedIn button opens in a new tab'
$pc = [regex]::Match($aboutHtml, 'class="?print-contact"?>(.*?)</p>').Groups[1].Value
Check (([regex]::Matches($pc, '<a href')).Count -eq 4) 'CV contact line has 4 links (email, LinkedIn, GitHub, site) so the PDF is clickable'
Check ($aboutHtml -match 'href="?https://github\.com/[^ >]+ target="?_blank"? rel="?me noopener"?') 'GitHub button opens in a new tab'

"`n== table of contents"
Check ((Html 'writing/lets-encrypt-certificate-for-prtg/index.html') -match 'toc-rail') 'ToC present on the long article'
Check (-not ((Html 'writing/the-veeam-restore-that-failed/index.html') -match 'toc-rail')) 'ToC absent on the short article'
$notesToc = Get-ChildItem (Join-Path $pub 'notes') -Recurse -Filter index.html | Where-Object { (Get-Content -Encoding UTF8 $_.FullName -Raw) -match 'toc-rail|toc-collapsed' }
Check ($notesToc.Count -eq 0) 'ToC never on notes'

"`n== copy-button hooks"
Check ((Html 'writing/the-veeam-restore-that-failed/index.html') -match 'class="?code-head"?') 'code blocks have a header bar for the copy button'

"`n== nothing leaks in the default config"
$leak = Get-ChildItem $pub -Recurse -File -Include *.html | Select-String -Pattern 'giscus\.app|cloudflareinsights|googletagmanager|gtag\(' -List
Check ($leak.Count -eq 0) "no analytics/comments markup emitted ($($leak.Count) files)"

"`n== per-page title / description / og:image"
$pages = Get-ChildItem $pub -Recurse -Filter index.html
$titles = @{}
foreach ($p in $pages) {
  $h = Get-Content -Encoding UTF8 $p.FullName -Raw
  $t = [regex]::Match($h, '<title>(.*?)</title>').Groups[1].Value
  $d = [regex]::Match($h, 'name="?description"? content="([^"]*)"').Groups[1].Value
  $og = [regex]::Match($h, 'property="?og:image"? content="?([^"\s>]+)').Groups[1].Value
  $rel = $p.FullName.Substring($pub.Length + 1)
  if ($titles.ContainsKey($t)) { "  DUPLICATE TITLE: $t ($rel)"; $fail++ } else { $titles[$t] = $rel }
  if (-not $d) { "  EMPTY DESCRIPTION: $rel"; $fail++ }
  if ($og) {
    $local = Join-Path $pub ($og -replace '^https://matacic\.net/', '')
    if (-not (Test-Path $local)) { "  MISSING og:image file: $og ($rel)"; $fail++ }
  } else { "  NO og:image: $rel"; $fail++ }
}
Check $true "$($pages.Count) pages checked for unique title, description, resolving og:image"
Check ((Html 'search/index.html') -match 'name="?robots"? content="?noindex') '/search/ carries noindex while disabled'

"`n== RSS"
foreach ($f in 'index.xml', 'writing/index.xml', 'notes/index.xml') {
  $ok = $true; try { [xml](Get-Content -Encoding UTF8 (Join-Path $pub $f) -Raw) | Out-Null } catch { $ok = $false }
  Check $ok "$f is well-formed XML"
}

"`n== CV PDF"
$cv = Join-Path $Root 'static\cv.pdf'
Check (Test-Path $cv) 'static/cv.pdf exists'
Check (Test-Path (Join-Path $pub 'cv.pdf')) 'cv.pdf is published to ./public'
Check ((Html 'about/index.html') -match 'href="?/cv\.pdf"? download') '/about/ offers the CV download'
if (Test-Path $cv) {
  # mtime only, so a fresh clone cannot judge this - it is a local reminder, not a gate on CI.
  $stamp = (Get-Item $cv).LastWriteTimeUtc
  $newer = 'content\about.md', 'layouts\about.html', 'data\certifications.yaml' |
    ForEach-Object { Join-Path $Root $_ } |
    Where-Object { (Test-Path $_) -and (Get-Item $_).LastWriteTimeUtc -gt $stamp }
  Check ($newer.Count -eq 0) "cv.pdf is newer than its sources$(if ($newer) { ' - stale, rerun scripts/build-cv-pdf.ps1 (changed: ' + (($newer | Split-Path -Leaf) -join ', ') + ')' })"
}

"`n== secrets"
$cfg = Get-Content (Join-Path $Root 'hugo.toml') -Raw
Check ($cfg -match 'cloudflareAnalyticsToken\s*=\s*""' -and $cfg -match 'repoId\s*=\s*""' -and $cfg -match 'ID\s*=\s*""') 'analytics + giscus IDs are empty in hugo.toml'

""
if ($fail -gt 0) { "RESULT: $fail check(s) failed"; exit 1 } else { "RESULT: all checks passed"; exit 0 }
