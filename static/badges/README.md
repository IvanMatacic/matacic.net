# Badge images

Badge artwork for the certifications listed in `data/certifications.yaml`. Each file is the
official Credly badge image, downloaded from the badge's public Credly page and scaled to
132×132 px (three times the 44 px slot on `/about/`) with a transparent background.

## Adding one

1. Add the certification to `data/certifications.yaml` with its `name`, `year` and Credly `id`.
2. Run from the repo root:

   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts/fetch-badges.ps1
   ```

   It fetches artwork for every item that has no `image:` line and prints the line to add.
3. Paste the printed `image: "badges/<file>.png"` under that item.

You can also drop any square PNG here by hand and point `image:` at it. Items without `image`
fall back to the issuer's mono initials on a tinted disc, so the section always renders
completely.
