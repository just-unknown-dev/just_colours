# Contributing to just_colours

Thank you for your interest in contributing to **just_colours**. We welcome all contributions: bug fixes, features, documentation improvements, and tests.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Features](#suggesting-features)
  - [Submitting a Pull Request](#submitting-a-pull-request)
- [Development Setup](#development-setup)
- [Project Layout](#project-layout)
- [Coding Guidelines](#coding-guidelines)
  - [General](#general)
  - [Picker UI](#picker-ui)
  - [Models and Saved Data](#models-and-saved-data)
  - [Tests](#tests)
- [Commit Message Convention](#commit-message-convention)
- [License](#license)

---

## Code of Conduct

This project follows our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you agree to abide by its terms. Please report unacceptable behaviour to the maintainers.

---

## Getting Started

1. **Fork** the repository on GitHub.
2. **Clone** your fork locally:
   ```bash
   git clone https://github.com/just-unknown-dev/just_colours.git
   cd just_colours
   ```
3. **Install dependencies:**
   ```bash
   flutter pub get
   ```
4. **Run tests and analysis** to make sure everything is green before you start:
   ```bash
   flutter test
   flutter analyze
   ```

---

## How to Contribute

### Reporting Bugs

Before opening an issue, please:
- Search [existing issues](https://github.com/just-unknown-dev/just_colours/issues) to avoid duplicates.
- Confirm the bug is reproducible on the latest version.

When opening a bug report, include:
- A clear, descriptive title.
- Steps to reproduce the problem.
- Expected vs. actual behaviour.
- Flutter and Dart versions (`flutter --version`) and the platform (Windows, macOS, Linux, Android, iOS, or web).
- How the picker was opened: `ColourPopover`, `JustColourDialog`, `ColourQuickPickerDialog`, or a `ColourPickerPanel` of your own, and which `ColourDialogView`.
- How you were using it: mouse, touch, or keyboard.
- For a gradient bug, the output of `gradient.toJson()`. For a saved-data bug, the JSON that would not load.
- For a visual bug, a screenshot, and whether the app's theme is light or dark.
- A minimal code sample or link to a reproduction repo if possible.

### Suggesting Features

- Open a [GitHub Discussion](https://github.com/just-unknown-dev/just_colours/discussions) or an issue labelled **`enhancement`**.
- Describe the problem your feature solves and how you'd like it to behave. For UI changes, a sketch or screenshot helps a lot.
- Check that the feature fits the package scope: picking and describing colours and gradients for Flutter tools and games, meaning the picker, the colour and gradient models, colour theory, presets, hex codes, and the colour library. Image editing and full design-system tooling are out of scope.

### Submitting a Pull Request

1. Create a topic branch from `main`:
   ```bash
   git checkout -b feat/my-new-feature
   ```
2. Make your changes, following the [Coding Guidelines](#coding-guidelines).
3. Add or update tests for any changed behaviour.
4. Ensure all tests pass and the code is formatted:
   ```bash
   flutter test
   flutter analyze
   dart format .
   ```
5. If your change is visible to users, add an entry to [CHANGELOG.md](CHANGELOG.md). Update the [README](README.md) if the public API changed.
6. Commit with a [conventional commit message](#commit-message-convention).
7. Push to your fork and open a Pull Request against `main`.
8. Fill in the PR template: describe what changed and why. For UI changes, include before and after screenshots, in a light and a dark theme if the change affects colours.
9. Address any review feedback promptly.

> **Small PRs are easier to review.** If your change is large, consider opening an issue first to discuss the approach.

---

## Development Setup

| Tool | Minimum Version | Recommended Version |
|------|------------------|---------------------|
| Dart SDK | 3.11.0 | latest stable |
| Flutter | 3.41.0 | latest stable |

`just_colours` is a Flutter package, so use the `flutter` tool rather than plain `dart` for pub and tests. Keep `lib/` free of `dart:io`, `dart:html` and `dart:js`, because the package must keep working on every platform, including the web. Anything that touches storage goes through `just_storage` and `just_database`, and only in `ColourStorageRepository`.

If you're working from the Just engine monorepo, run commands from `packages/just_colours`.

```bash
# Fetch dependencies
flutter pub get

# Run tests
flutter test

# Analyze and format
flutter analyze
dart format .
```

---

## Project Layout

| Path | What lives there |
|------|------------------|
| `lib/src/models/` | `ColourSelection`, `GradientConfig`, `GradientStop`, `ColourPalette`, `NamedGradient` |
| `lib/src/library/` | `ColourLibrary`: recent colours, palettes and gradients |
| `lib/src/storage/` | `ColourStorageRepository`: on-device persistence |
| `lib/src/theory/` | `ColourTheory`: harmonies and shades |
| `lib/src/presets/` | Built-in palettes and gradients |
| `lib/src/utils/` | `ColourCodec`: hex encoding and parsing |
| `lib/src/ui/picker/` | The picker: `ColourPickerPanel` and the solid, gradient and swatch editors inside it |
| `lib/src/ui/widgets/` | The controls the picker is built from: strips, square, stop bar, fields, swatches |
| `lib/src/ui/` | The hosts: `ColourPopover`, `JustColourDialog`, `ColourQuickPickerDialog` |

Everything public is exported from `lib/just_colours.dart`.

---

## Coding Guidelines

### General

- Follow the official [Dart style guide](https://dart.dev/guides/language/effective-dart/style).
- All public APIs must have **doc comments** (`///`).
- Prefer `const` constructors wherever possible.
- Do not introduce new dependencies without prior discussion in an issue.
- Match the existing file and folder structure under `lib/src/`.
- Prefer deterministic behaviour and avoid hidden global state. `ColourLibrary.session` is the one deliberate exception.

### Picker UI

- **Take every colour and text style from the ambient `Theme`**, through `PickerLook`. Never hard-code a colour for chrome. The only exceptions are the checkerboard and the white and black outlines that keep handles visible on any colour. Apps theme the picker by wrapping it, and a hard-coded colour breaks that.
- **Every control works from the keyboard.** It must be focusable, show a focus ring, and respond to the arrow keys (Shift for bigger steps) where that makes sense. Escape cancels and Enter applies anywhere in the picker.
- **Every control has a semantics label.** Screen readers need to know what a swatch, handle or strip is and what value it holds.
- **Layouts must not overflow.** Check at the popover's 340 px width, with large text, and in widget tests, whose test font is wider than real fonts. Let labels shrink with `Flexible` and an ellipsis rather than fixing widths.
- **What the picker shows is what comes back.** A preview must match what the caller will draw, including the tint over a gradient.
- **The picker reports and never saves.** Changes go to `onChanged`, and the result goes back to the caller. Only `ColourLibrary` remembers anything.
- **No dialog on top of the picker** for routine work. Edit in place. A small prompt for something rare, like renaming a palette, is fine.
- Text the user sees uses the **"colour"** spelling, as in the package name, and sentence case.

### Models and Saved Data

- Models are **immutable**. When you add a field, add it to `copyWith`, `toJson`, `fromJson`, `==` and `hashCode`.
- **Saved JSON must keep loading.** New fields are optional, with a default that matches the old behaviour. Never rename or reuse a key. Add a test that reads JSON written before your change.
- A `GradientConfig` must always be drawable. Keep `stops` the same length as `colors`, or `null`, and handle a gradient with fewer than two colours without throwing.

### Tests

- Model, theory, codec and library changes need unit tests in `test/just_colours_test.dart`.
- Picker changes need widget tests in `test/picker_widget_test.dart`. Drive them the way a user would: tap, type, drag, or press keys.
- Bug fixes come with a test that fails without the fix.

---

## Commit Message Convention

We use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <short summary>
```

| Type | When to use |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `test` | Adding or updating tests |
| `chore` | Build process, tooling, dependencies, releases |

Common scopes: `picker`, `gradient`, `library`, `storage`, `theory`, `codec`, `presets`.

**Examples:**
```
feat(presets): add a dusk gradient to the built-in presets
fix(picker): keep the hue when the colour passes through grey
docs(contributing): add the picker UI guidelines
```

---

## License

By contributing to this repository, you agree that your contributions will be licensed under the [BSD-3-Clause License](LICENSE).
