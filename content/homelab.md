---
title: "Homelab"
description: "Current homelab hardware and what runs where — the reference I keep for myself."
layout: "homelab"
heading: "Current setup"
hardware:
  - host: "esxi-01"
    role: "Hypervisor"
    specs: "PLACEHOLDER · CPU / RAM / disk"
    notes: "Main VM host"
  - host: "nas-01"
    role: "Storage"
    specs: "PLACEHOLDER · pool / RAID level"
    notes: "NFS + iSCSI datastores"
  - host: "rtr-01"
    role: "Router"
    specs: "PLACEHOLDER · model / firmware"
    notes: "VLANs, WireGuard"
services:
  - host: "esxi-01"
    runs: "vCenter, Grafana, Gitea"
  - host: "nas-01"
    runs: "Veeam repository, media"
  - host: "rtr-01"
    runs: "DNS, DHCP, cloudflared"
---

Three nodes, one switch and more services than are strictly necessary. This page is the reference I keep for myself — what runs where, and on which box. Rows marked PLACEHOLDER are waiting for the real specs.
