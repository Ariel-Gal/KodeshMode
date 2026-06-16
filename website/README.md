# KodeshMode website

Modern static landing page for KodeshMode, the free and open source Garmin Connect IQ Shabbat mode watch app.

## Run locally

```bash
npm install
npm run dev
```

## Build

```bash
npm run build
```

The default build uses a dependency-light static copy script and writes to `dist/`. Vite is still available for development and preview:

```bash
npm run build:vite
npm run preview
```

## Security check

```bash
npm run check:security
```

The check verifies CSP presence, safe external links, no inline event handlers, no unsafe dynamic HTML APIs, no tracking scripts, and image alt text.

## Assets

Brand and screenshot assets are stored in:

```text
website/public/images/brand/
website/public/images/showcase/
```

The official KodeshMode app logo is used for the site header, hero lockup, Open Graph image, favicon, Apple touch icon, and web app manifest. Uploaded PNG assets have matching optimized WebP variants where useful, with PNG fallback.
