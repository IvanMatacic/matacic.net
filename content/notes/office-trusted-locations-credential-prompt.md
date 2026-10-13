---
title: "Prompt for credentials when accessing Office documents"
date: 2017-11-06
tags: ["credentials", "excel", "network-drive", "network-location", "office", "word"]
summary: "Word or Excel asks for password while opening documents on Sharepoint network location or mapped network drive in Windows."
slug: "office-trusted-locations-credential-prompt"
draft: false
---

In previous post I showed you how to [force Windows to use saved passwords for network locations](/notes/windows-webdav-saved-password/). But my problem still persist in some other way. While trying to open Office document on network location or mapped network drive, Word or Excel asks for password instead of use saved credentials.

To resolve the problem, add your server's URL in Trusted Locations:

1. Open Word or Excel
2. Click **File > Options > Trust Center > Trust Center Settings… > Trusted Locations**
3. Check option **Allow Trusted Locations on my network** and then **Add new location…**
4. Enter URL of your server or click Browse to browse to network location or mapped network drive
5. Check option **Subfolders of this location are also trusted** to get rid of asking for credentials while accessing files in subfolders

![Office Trusted Locations dialog with a network path added](/images/office-trusted-locations-credential-prompt/trusted-location.jpg)
