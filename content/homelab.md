---
title: "Homelab"
description: "Current homelab hardware and what runs where — the reference I keep for myself."
layout: "homelab"
heading: "Current setup"
services:
  - host: "esxi-01"
    runs: "vCenter, Grafana, Gitea"
  - host: "nas-01"
    runs: "Veeam repository, media"
  - host: "rtr-01"
    runs: "DNS, DHCP, cloudflared"
---

Three nodes, one switch and more services than are strictly necessary. This page is the reference I keep for myself — what runs where, and on which box. Rows marked PLACEHOLDER are waiting for the real specs.

| Host | Role | Specs | Software |
| --- | --- | --- | --- |
| pve1 | virtualization host | **Lenovo M90q** · i5-10500T / 64GB / 250GB NVMe + 480GB SATA SSD | Proxmox VE 9.2 |
| pve2 | virtualization host | **Lenovo M90q** · i5-10500T / 64GB / 250GB NVMe + 480GB SATA SSD | Proxmox VE 9.2 |
| truenas | NAS | **Custom PC** · i5-6500 / 24GB /  | TrueNAS 25.10 |
| rtr-01 | Router | Mikrotik Chateau LTE18 / 7.24.5 | VLANs, WireGuard |
