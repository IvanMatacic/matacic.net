---
title: "Windows won't use saved password for network location"
date: 2017-11-04
tags: ["network-drive", "network-location", "registry", "webdav", "windows"]
summary: "Windows not using saved password when accessing WebDav network location or mapped network drive hosted on Sharepoint site."
slug: "windows-webdav-saved-password"
draft: false
---

I have connected a few shared network locations on a Windows 10 computer which is not in the domain. Although credentials are saved, seems like Windows not using it, so user must type password after every reboot or sign out. Network folders are on Sharepoint site and are accessed using WebDav protocol.

At first I tried to change Internet settings for Local Intranet Zone:

1. Open **Control Panel > Internet Properties > Security > Local Intranet** tab
2. Click on **Custom level…** and scroll down to the last option **User Authentication**
3. Under the **Logon** select **Automatic logon with current user name and password**

But problem still persisted. Because intranet site has periods in the URL, Windows assumes it's on the Internet.

One registry entry solved the problem:

1. Open **regedit**
2. Navigate to following registry entry: `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WebClient\Parameters`
3. Add new **Multi-String Value** name it **AuthForwardServerList**
4. **Modify** the key and in the **Value data** box enter URL of the server that host the site

You can use asterisk (\*) charachter as wildcard (e.g. \*.example.com or \*example.com and also example.\* or example\*.com).

Find more details in [Microsoft KB94328](https://support.microsoft.com/en-us/help/943280/prompt-for-credentials-when-you-access-webdav-based-fqdn-sites-in-wind).
