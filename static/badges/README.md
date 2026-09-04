# Badge images

Drop the real badge PNG for a certification into this folder, then point the
matching item in `data/certifications.yaml` at it:

```yaml
- name: "VBR v11: Architecture & Design (VMCA 2022)"
  year: 2021
  id: "d848d336-3c4a-46e3-9566-e8d55921bcc6"
  image: "badges/veeam-vmca.png"   # path relative to static/
```

Guidelines:

- Square PNG, 176×176 px or larger (Credly badges are usually 340×340). The
  template renders it at 44×44 and sets `width`/`height` for layout stability.
- Keep file names lowercase and hyphenated: `issuer-badge.png`.
- Items without `image` fall back to the issuer's mono initials on a tinted disc,
  so the section always renders completely.
