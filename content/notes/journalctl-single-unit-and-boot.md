---
title: "Filtering journalctl to a single unit and boot"
date: 2026-08-22
tags: ["linux", "systemd"]
summary: "Scope the journal to one unit and the current boot, and the noise disappears."
slug: "journalctl-single-unit-and-boot"
draft: false
---

Scrolling the whole journal to find one service's last failure is wasted time. Scope it to the unit and the current boot, and the noise disappears.

```bash
journalctl -u cloudflared -b -p warning --no-pager
```

`-u` picks the unit, `-b` limits output to the current boot, and `-p warning` drops everything below warning priority. Add `-f` to follow it live, or `-b -1` to read the boot *before* the reboot that hid the evidence.
