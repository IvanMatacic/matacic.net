---
title: "How to extract the Veeam license from the Windows registry"
date: 2026-10-28
tags: ["veeam", "registry", "windows"]
summary: "When the installer asks for a .lic file you don't have, the license is already in the registry."
slug: "extract-veeam-license"
draft: false
---

I tried to install Veeam Backup Enterprise Manager on a server that already runs Veeam Backup & Replication v13.1. The installer doesn't pick up the license that's already installed. Instead, it asks for a `.lic` file. If you don't have the file at hand, you can pull it out of the registry.

The license is stored as a binary value (`REG_BINARY`) named `License` under `HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication`. Because it's binary, copying it out of regedit doesn't work. You need to write the raw bytes to a file instead:

```powershell
$key   = 'HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication\license'
(Get-Item $key).GetValueNames()	# just for a quick check

$bytes = (Get-ItemProperty $key).Lic1
[IO.File]::WriteAllBytes("$env:TEMP\veeam.lic", $bytes)

# quick sanity check — should look like a readable license file
[Text.Encoding]::ASCII.GetString($bytes[0..300])
```

Voila! The license file is in `%TEMP%\veeam.lic`, so point the installer to it.

The proper way is still to download the license from [my.veeam.com](https://my.veeam.com). This is the fallback when you don't have portal access. The `.lic` file contains your company and contract details, so treat it accordingly.
