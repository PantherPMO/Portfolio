# Shared Assets

Portfolio-wide visual assets. Anything used by more than one project lives here; project-specific images stay in that project's `outputs/figures/`.

```
_assets/
├── README.md
├── palette/          Shared colour tokens
├── logos/            Personal mark / wordmark, if used
├── covers/           Hero images for each project README
└── icons/            Shared iconography
```

## Rules

- **Hero images** are named `NN-project-slug-hero.png` and sized 1200×630 (GitHub social preview ratio).
- **No stock photography.** Portfolio imagery is charts, dashboards and diagrams — the work itself.
- **Every image must be legible at GitHub's rendered width (~880px).** Screenshot dashboards at 2× and downscale rather than screenshotting at native size.
- **Colour must match** the shared palette in `palette/`. A portfolio where every project uses different colours looks like eight unrelated pieces of work.
- Keep files under 500 KB where possible; use PNG for dashboards and diagrams, SVG for vector diagrams.
