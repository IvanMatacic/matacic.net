---
title: "Listing VM world IDs from the ESXi shell"
date: 2026-07-30
tags: ["vmware", "esxi"]
summary: "When vCenter cannot power off a hung VM, the ESXi shell can — once you know its World ID."
slug: "esxi-vm-world-ids"
draft: false
---

When a VM hangs so hard that vCenter's *Power Off* just spins, the fix is on the host itself. Every running VM has a World ID, and `esxcli` will list them along with the display name and the VMX path, so you can be sure you are about to kill the right one.

```bash
esxcli vm process list
esxcli vm process kill --type=soft --world-id=2101234
```

Start with `--type=soft`; it asks the guest to shut down. If that does nothing after a minute, escalate to `hard`, and only then to `force`, which is the equivalent of pulling the power cord. Check the process list again afterwards — the entry should be gone before you power the VM back on from vCenter.
