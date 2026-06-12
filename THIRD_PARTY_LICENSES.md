# Third-party licenses and notices

This repository contains app source code, Garmin Connect IQ resources, generated bitmap fonts, and screenshots.

The app source code is licensed under the MIT License. Third-party fonts and generated font assets remain under their original licenses.

## Fonts

| Asset | Files / generated assets | License | Notes |
| --- | --- | --- | --- |
| Varela Round | `tools/VarelaRound-Regular.ttf`, generated `resources/fonts/varela_*` assets | SIL Open Font License 1.1 | See `LICENSES/OFL-1.1.txt`. |
| Culmus Simple CLM | `tools/simpleclm-boldoblique-webfont.ttf`, generated `resources/fonts/simple_*` assets | GNU GPL v2, commonly distributed by Culmus with a font/document embedding exception for some fonts | See `LICENSES/GPL-2.0-only.txt` and `LICENSES/CULMUS-FONT-EXCEPTION-NOTE.md`. Verify the exact upstream notice before publishing a public release. |
| Culmus Stam Ashkenaz CLM | `tools/stamashkenazclm-webfont.ttf`, generated `resources/fonts/stam_*` assets | GNU GPL v2, commonly distributed by Culmus with a font/document embedding exception for some fonts | See `LICENSES/GPL-2.0-only.txt` and `LICENSES/CULMUS-FONT-EXCEPTION-NOTE.md`. Verify the exact upstream notice before publishing a public release. |

## Screenshots

Screenshots in `screenshots/` and generated README images in `docs/images/` are documentation assets for this repository.

## Publishing checklist

Before publishing a release:

1. Confirm that every original font file in `tools/` is allowed to be redistributed.
2. Keep each font's upstream copyright/license notice in the repository.
3. Confirm whether generated `.fnt` / `.png` bitmap font assets are considered derivatives under the relevant font license.
4. Do not publish private Garmin developer keys, build output, local logs, or simulator artifacts.

This file is a project notice, not legal advice.
