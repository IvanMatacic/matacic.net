---
title: "How to view system uptime on IBM Storwize"
date: 2018-07-04
tags: ["ibm", "storage", "storwize", "uptime"]
summary: "Workaround to view system uptime on IBM Storwize V3700 V5000 V7000 storages using GUI and dump logs."
slug: "storwize-uptime-from-support-package"
draft: false
---

I have a few IBM Storwize V3700, V5000 and V7000 storages. Few days ago I had to check system uptime on one of the storages. Unfortunately, you can't do that directly. There's no command (like `uptime` on Linux) nor GUI shows it. But there's a workaronud.

1. Login to Web GUI
2. Choose **System** > **Support**
3. Click **Download Support Package**
4. Wait a few minutes for package to be generated
5. Download last **/dumps/snap.\<some-numbers\>.tgz**

Now open the archive and navigate to **/dumps/syslog** folder. Open **mcelog.\<some-numbers\>-1** and **mcelog.\<some-numbers\>-2** files. You will see date and time of node booting. Files 1 and 2 are for left and right node. It's still not the real uptime, but you can easily calculate it.
