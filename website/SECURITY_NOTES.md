# Website security notes

This landing page is intentionally static and lightweight.

## Implemented safety checks

- No external JavaScript, Google Fonts, analytics scripts, tracking pixels, or public CORS proxy calls.
- GitHub release notes are rendered with safe DOM APIs and `textContent`; raw remote Markdown/HTML is not injected into the page.
- External URLs read from APIs are restricted to expected HTTPS hostnames before being assigned to `href` or `src`.
- No user-controlled HTML rendering, `innerHTML`, `DOMParser`, `eval`, or inline event handlers.
- JavaScript toggles CSS classes instead of writing inline style attributes.
- All `target="_blank"` links use `rel="noopener noreferrer"`.
- CSP is defined in HTML for static hosts and in `public/_headers` for hosts that support response headers.
- `public/_headers` includes stricter HTTP headers for hosts such as Netlify or Cloudflare Pages.
- The local Vite dev and preview scripts bind to localhost by default instead of `0.0.0.0`.
- The page includes `prefers-reduced-motion` support.
- Images are local, except GitHub contributor avatars, and include descriptive alt text.

## Notes for GitHub Pages

GitHub Pages does not apply custom response headers from `public/_headers`. The CSP meta tag still provides a useful baseline, but headers such as `X-Frame-Options`, `frame-ancestors`, and `Permissions-Policy` require a host that supports custom HTTP headers.

## Verification

Run:

```bash
npm run check
```

This builds the static site and performs local checks for common static-site safety issues.
