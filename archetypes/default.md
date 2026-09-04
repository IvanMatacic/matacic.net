---
title: "{{ replace .File.ContentBaseName "-" " " | title }}"
date: {{ .Date }}
lastmod: {{ .Date }}
topics: []            # one topic, e.g. ["Homelab"] — drives /topics/<topic>/ and the homepage rail
tags: []              # a few lowercase tags, e.g. ["cloudflare", "networking"]
summary: ""           # one or two sentences; used on lists, in meta description and in llms.txt
slug: "{{ .File.ContentBaseName }}"
draft: true
# toc: true           # force the table of contents even under 600 words
# image: ""           # custom Open Graph image, path under static/
---

Intro paragraph: what broke, what you were trying to do, why it matters.

## First section

### A sub-point

```bash
echo "commands go in fenced blocks with a language"
```

## Takeaway

One paragraph the reader can act on.
