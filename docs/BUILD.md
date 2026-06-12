# Build guide

## Prerequisites

- Garmin Connect IQ SDK
- Java runtime required by Garmin tooling
- Garmin developer key
- Visual Studio Code with the Monkey C extension, or Garmin CLI tools

## Clean build checklist

Before building a release candidate:

1. Delete generated folders:

   ```bash
   rm -rf bin gen .logs build out
   ```

2. Confirm no private keys are present in the repository.
3. Build for at least one MIP device and one AMOLED device.
4. Open the simulator and verify Hebrew rendering.
5. Verify phone-side settings.
6. Verify touch-watch behavior.

## Example CLI build

```bash
monkeyc -f monkey.jungle -d fenix7 -o bin/KodeshMode.prg -y path/to/developer_key.der
```

## Example simulator run

```bash
monkeydo bin/KodeshMode.prg fenix7
```

## Recommended simulator targets

- `fenix7` for MIP behavior
- `venu3` or `vivoactive5` for touch AMOLED behavior
- `fr965` for high-resolution AMOLED behavior
- `instinct3solar45mm` for Solar / MIP layout behavior

## Release notes

Update `CHANGELOG.md` before creating a GitHub release.
