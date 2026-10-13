---
title: "How to renew Let's encrypt certificate for PRTG"
date: 2018-08-13
tags: ["certificate", "letsencrypt", "prtg", "ssl"]
summary: "Find out how to renew Let's encrypt certificate for PRTG on Windows Server."
slug: "prtg-lets-encrypt-renewal"
draft: false
---

In one of the last posts I've showed you [how to install Let's encrypt certificate on PRTG](/writing/lets-encrypt-certificate-for-prtg/). As Let's encrypt certificate is valid for only 90 days, now it's time to renew it. Process is simple, but require some manual work.

1. Start **letsencrypt.exe** and choose **S** for Renew specific

    ![win-acme menu with the Renew specific option selected](/images/prtg-lets-encrypt-renewal/win-acme-1.png)

2. Enter the number of the certificate you wish to renew

    ![win-acme listing the certificates available for renewal](/images/prtg-lets-encrypt-renewal/win-acme-2-1.png)

3. If certificate renew process went successful, you'll see this screen

    ![win-acme reporting a successful renewal](/images/prtg-lets-encrypt-renewal/win-acme-3-1.png)

Now open **PRTGCertImporter.exe** and import certificate like in [previous post](/writing/lets-encrypt-certificate-for-prtg/).
