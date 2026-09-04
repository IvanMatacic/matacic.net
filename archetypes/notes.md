---
title: "{{ replace .File.ContentBaseName "-" " " | title }}"
date: {{ .Date }}
tags: []              # a few lowercase tags, e.g. ["linux", "systemd"]
summary: ""           # one sentence; shown in the notes list, meta description and llms.txt
slug: "{{ .File.ContentBaseName }}"
draft: true
---

Three to eight sentences. State the gotcha, show the one command that fixes it,
say when it applies.

```bash
command --that --fixes it
```
