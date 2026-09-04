---
title: "Mikrotik export hides default values — use verbose"
date: 2026-08-11
tags: ["mikrotik", "routeros", "networking"]
summary: "A plain /export omits every setting still at its default, which makes two configs look different when they are not."
slug: "mikrotik-export-hides-defaults"
draft: false
---

A plain `/export` on RouterOS prints only the settings that differ from their defaults. That keeps the output short, but it also means a diff between two routers shows lines "missing" on one side when the value is simply still at default there. It bit me while comparing a firewall filter chain between two identical models: one had `log=no` shown, the other did not, and they were behaving the same way.

```routeros
/export verbose file=full-config
```

`verbose` writes every parameter, default or not, so the export is complete and diffs are meaningful. On RouterOS 7 you can add `show-sensitive` if you also need the secrets in the file — and then treat that file accordingly.
