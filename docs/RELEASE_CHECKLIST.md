# Release checklist

Use this checklist before publishing a GitHub release or Garmin Connect IQ Store build.

## Repository hygiene

- [ ] `bin/`, `gen/`, `.logs/`, `.venv/`, and local IDE files are not committed.
- [ ] Garmin developer keys are not committed.
- [ ] Generated screenshots are current.
- [ ] README badges point to the correct repository.
- [ ] `CHANGELOG.md` is updated.
- [ ] License and third-party notices are included.

## Functional testing

- [ ] App launches on a MIP simulator.
- [ ] App launches on an AMOLED simulator.
- [ ] Hebrew parasha renders correctly.
- [ ] Hebrew status text renders correctly.
- [ ] Hebrew date renders correctly.
- [ ] Shabbat times render correctly.
- [ ] Battery display works.
- [ ] Phone-side settings change the expected UI values.
- [ ] Touch watches do not expose confusing in-watch settings.
- [ ] Button watches handle menu/back/select behavior correctly.

## Device families

- [ ] fēnix / MIP
- [ ] epix / AMOLED
- [ ] Forerunner
- [ ] Venu / vivoactive touch watches
- [ ] Instinct / Solar where supported

## Store listing

- [ ] App description ready.
- [ ] Screenshots selected.
- [ ] Permissions explained.
- [ ] Privacy note reviewed.
- [ ] Version number updated.
