# Contributing to KodeshMode

Thank you for considering a contribution.

## Good ways to help

- Test on additional Garmin devices.
- Add screenshots from real devices or the simulator.
- Improve Hebrew rendering and typography.
- Fix Hebrew or English strings.
- Verify parasha and Hebrew date edge cases.
- Test zmanim with different locations.
- Improve documentation.

## Development setup

1. Install the Garmin Connect IQ SDK.
2. Install Visual Studio Code and the Garmin Monkey C extension, or use Garmin CLI tools.
3. Clone the repository.
4. Open the project folder in VS Code.
5. Build for a supported simulator device such as `fenix7`.

## Pull request checklist

Before opening a pull request:

- Run a clean build.
- Delete local `bin/`, `gen/`, `.logs/`, and other generated artifacts before committing.
- Do not commit Garmin developer keys.
- Do not commit private `.env` files.
- Add or update screenshots when changing the UI.
- Update `CHANGELOG.md` for user-visible changes.
- Confirm that all Hebrew strings render correctly on at least one MIP and one AMOLED simulator when possible.

## Coding guidelines

- Keep Hebrew user-facing strings in resource files where possible.
- Avoid drawing Hebrew with Garmin system fonts unless confirmed on the target device.
- Prefer device-specific layout helpers over hard-coded positions.
- Keep touch-watch behavior phone-settings-first.
- Avoid converting the project to a watch face unless the product direction changes.

## Issues

When reporting a bug, include:

- Garmin model or simulator target
- Connect IQ SDK version
- App version or commit hash
- Screenshot or short video if the issue is visual
- Expected behavior
- Actual behavior
- Steps to reproduce
