# Contributing to TeaShot

Thanks for helping. TeaShot is a small, native macOS utility, and contributions that keep it small and native are the most welcome: bug fixes, accessibility improvements and localizations in particular.

## Before you start

- For anything larger than a bug fix, open an issue first so we can agree on the approach.
- TeaShot uses only Apple frameworks. Please do not add third-party dependencies.

## Set up

You need Xcode 27 or later; the app itself runs on macOS 14 or later. No Apple developer account is needed: builds are signed to run locally.

```sh
git clone https://github.com/PillowPillow/tea-shot.git
cd tea-shot
make test
```

Open `TeaShot.xcodeproj` in Xcode, or use the Makefile targets listed in the [README](README.md#development).

## Pull requests

- Keep each pull request focused on one change.
- Add or update tests in `TeaShotTests/` for any behaviour change. The suite uses Swift Testing.
- Run `make format`, then `make lint` and `make test`. CI runs the last two on every pull request.
- Interface text is in French for now. If you add a string, keep it in French; localizations are welcome as separate pull requests.
- Check the change with VoiceOver when it touches the menu or Settings.

By contributing, you agree that your contribution is licensed under the [GNU GPL v3.0](LICENSE).
