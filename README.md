# Just Colours

`just_colours` is a Flutter colour toolkit for game tools and creative UI workflows.
It includes:

- Colour and gradient picker dialogs
- Colour theory helpers (complementary, triadic, analogous, and more)
- Ready-to-use palette and gradient presets
- Hex encoding/decoding helpers
- Optional persistence for recent colours, gradients, palettes, and history

## Features

- **Interactive pickers**: `ColourQuickPickerDialog` and `JustColourDialog`
- **Gradient model**: `GradientConfig` with linear/radial/sweep support
- **Theory utilities**: `ColourTheory` harmony methods
- **Presets**: curated palettes and gradients in `ColourPresets`
- **Serialization**: JSON-ready models (`ColourSelection`, `ColourPalette`, `GradientConfig`)
- **Storage repository**: `ColourStorageRepository` backed by `just_storage` and `just_database`

## Getting Started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
	just_colours: ^0.0.1
```

Then import:

```dart
import 'package:just_colours/just_colours.dart';
```

## Usage

### Pick a single colour quickly

```dart
final Color? picked = await ColourQuickPickerDialog.show(
	context,
	initialColor: const Color(0xFFF5746F),
	title: 'Pick Accent Color',
);

if (picked != null) {
	// Use the chosen color.
}
```

### Open the full colour + gradient studio

```dart
final repo = await ColourStorageRepository.create();

final ColourSelection? result = await JustColourDialog.show(
	context,
	view: ColourDialogView.both,
	initialSelection: const ColourSelection(
		color: Color(0xFF2E4EA8),
		useGradient: true,
	),
	repository: repo,
);

if (result != null) {
	final paint = result.useGradient
			? Paint()..shader = result.gradient.toGradient().createShader(
					const Rect.fromLTWH(0, 0, 300, 300),
				)
			: Paint()..color = result.color;
}

await repo.close();
```

### Choose what the dialog should show

```dart
// Color picker only
await JustColourDialog.show(
	context,
	view: ColourDialogView.colourOnly,
);

// Gradient editor only
await JustColourDialog.show(
	context,
	view: ColourDialogView.gradientOnly,
);

// Both tabs (default)
await JustColourDialog.show(
	context,
	view: ColourDialogView.both,
);
```

### Build colour harmony sets

```dart
const base = Color(0xFF00AACC);

final complementary = ColourTheory.complementary(base);
final analogous = ColourTheory.analogous(base);
final triadic = ColourTheory.triadic(base);
final tetradic = ColourTheory.tetradic(base);
final monochrome = ColourTheory.monochromatic(base, count: 6);
```

### Use built-in presets

```dart
final palette = ColourPresets.palettes.first;
final gradient = ColourPresets.gradients.first;

final Color primary = palette.colors.first;
final Gradient uiGradient = gradient.toGradient();
```

### Encode and decode hex values

```dart
final hex = ColourCodec.toHex(const Color(0xFFF5746F)); // #FFF5746F
final color = ColourCodec.fromHex('#2E4EA8');
```

### Persist user selections

```dart
final repo = await ColourStorageRepository.create();

const selection = ColourSelection(
	color: Color(0xFF121212),
	gradient: GradientConfig(
		type: GradientType.linear,
		angle: 45,
		colors: [Color(0xFF121212), Color(0xFF00E5FF)],
	),
	useGradient: true,
);

await repo.saveCurrentSelection(selection);
await repo.appendHistory(selection);

final loaded = await repo.loadCurrentSelection();
final history = await repo.listHistory(limit: 10);

await repo.close();
```

## API Overview

- `ColourSelection`: selected base colour + gradient mode/config
- `GradientConfig`: gradient type, colors, stops, angle, center, radius
- `ColourPalette`: named colour collections
- `ColourPresets`: package-provided palettes and gradients
- `ColourTheory`: harmony calculators
- `ColourCodec`: hex conversion helpers
- `ColourStorageRepository`: optional persistence and history

## Additional Information

- Source: https://github.com/just-unknown-dev/just-game-engine
- Package path: `packages/just_colours`
- Current version: `0.0.1`

Issues and improvements are welcome through the repository issue tracker.
