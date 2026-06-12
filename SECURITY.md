# Security Policy

## Supported versions

Security updates are handled on the latest `main` branch unless a release branch is explicitly maintained.

## Reporting a vulnerability

Please do not open public GitHub issues for security-sensitive reports.

Instead, contact the maintainer privately using the contact method listed in the GitHub profile or repository metadata.

Please include:

- A clear description of the issue
- Steps to reproduce
- Affected device or simulator target
- Connect IQ SDK version
- Any relevant logs or screenshots that do not contain private information

## Sensitive files

Never commit:

- Garmin developer keys
- Signing certificates
- `.env` files
- Local build logs containing private paths or tokens
- Packaged `.prg` files intended only for private testing
