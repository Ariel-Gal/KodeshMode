# Website security notes

This landing page is intentionally static and lightweight.

## Implemented safety checks

- No external JavaScript or third-party analytics scripts.
- No Google Fonts or remote font loading; the page uses system fonts.
- No user-controlled HTML rendering, `innerHTML`, `eval`, or inline event handlers.
- All `target="_blank"` links use `rel="noopener noreferrer"`.
- A restrictive CSP meta tag is included for static hosts.
- `public/_headers` includes stricter HTTP headers for hosts that support header files such as Netlify or Cloudflare Pages.
- The page includes `prefers-reduced-motion` support.
- Images are local and include descriptive alt text.

## Notes for GitHub Pages

GitHub Pages does not apply custom response headers from `public/_headers`. The CSP meta tag still provides a useful baseline, but headers such as `X-Frame-Options` and `Permissions-Policy` require a host that supports custom HTTP headers.

## Verification

Run:

```bash
npm run check
```

This builds the static site and performs local checks for common static-site safety issues.
