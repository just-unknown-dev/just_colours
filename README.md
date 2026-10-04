# Just Colours

`just_colours` is a Flutter colour toolkit for game tools and creative UI workflows.
It includes:

- A colour and gradient picker, as a popover beside a field or as a dialog
- Colour theory helpers (complementary, triadic, analogous, shades, and more)
- Ready-to-use palette and gradient presets
- Hex encoding/decoding helpers
- A colour library for recent colours, saved palettes and gradients, kept wherever you choose

## Features

- **Pickers**: `ColourPopover`, `JustColourDialog`, `ColourQuickPickerDialog`, and the bare `ColourPickerPanel`
- **Solid or gradient**: the switch at the top of the picker is what comes back
- **Gradients**: linear, radial and sweep, any number of colours, shaped by hand on the preview
- **Live editing**: every change reaches `onChanged` as it happens
- **Theming**: the picker draws only from the ambient `Theme`
- **Theory utilities**: `ColourTheory` harmonies, named for the picker
- **Library**: `ColourLibrary`, with `ColourStorageRepository` to keep one on the device

## Getting Started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
	just_colours: ^0.1.0
```

Then import:

```dart
import 'package:just_colours/just_colours.dart';
```

## Usage

### Open the picker beside a field

```dart
final ColourSelection? result = await ColourPopover.show(
	context, // the field's context: the picker opens beside it
	initialSelection: const ColourSelection(color: Color(0xFF2E4EA8)),
	view: ColourDialogView.both, // or colourOnly / gradientOnly
	onChanged: (selection) {
		// Called on every change while the picker is open: show it live.
	},
);

if (result != null) {
	final paint = result.useGradient
			? (Paint()
					..shader = result.gradient.toGradient().createShader(
						const Rect.fromLTWH(0, 0, 300, 300),
					))
			: (Paint()..color = result.color);
}
```

A click outside the popover applies, as Apply does; Escape cancels and
returns null. `JustColourDialog.show` takes the same arguments and opens the
picker in the middle of the screen.

### Pick a single colour

```dart
final Color? picked = await ColourQuickPickerDialog.show(
	context,
	initialColor: const Color(0xFFF5746F),
	title: 'Accent',
);
```

### Fit the picker to your app

The picker takes its colours and text from the ambient `Theme`. To give it
a different one — or anything else it should sit inside — pass `builder`:

```dart
await ColourPopover.show(
	context,
	builder: (context, picker) => Theme(data: myToolTheme, child: picker),
);
```

### Recent colours, palettes and gradients

Give the picker a `ColourLibrary`, and keep it where you like.
`recentsChanged` and `collectionsChanged` fire separately, so recent colours
can stay with the user while palettes travel with a project:

```dart
final library = ColourLibrary()
	..loadCollections(jsonDecode(projectFile.readAsStringSync()));
library.collectionsChanged.addListener(() {
	projectFile.writeAsStringSync(jsonEncode(library.collectionsToJson()));
});

await ColourPopover.show(context, library: library);
```

Without one, the picker uses `ColourLibrary.session`: recent colours for as
long as the app runs. To keep everything on the device:

```dart
final repo = await ColourStorageRepository.create();
final library = await repo.loadLibrary();
```

### Eyedropper and tint

```dart
await ColourPopover.show(
	context,
	// Reads the colour drawn at a point on screen; the eyedropper shows
	// only with one.
	sampler: (globalPosition) async => readPixelAt(globalPosition),
	// Offers a tint, multiplied over gradients, for renderers that draw
	// ColourSelection.tint.
	showTint: true,
);
```

### Build colour harmony sets

```dart
const base = Color(0xFF00AACC);

final complementary = ColourTheory.complementary(base);
final triadic = ColourTheory.triadic(base);
final shades = ColourTheory.shades(base, count: 7);

for (final harmony in ColourTheory.harmonies(base)) {
	print('${harmony.name}: ${harmony.colors.length} colours');
}
```

### Edit gradients in code

```dart
var gradient = const GradientConfig(
	colors: [Color(0xFF121212), Color(0xFF00E5FF)],
	angle: 45,
);

gradient = gradient.withStopList([
	...gradient.stopList,
	const GradientStop(Color(0xFFFFEA00), 0.5),
]);
gradient = gradient.reversed();
final middle = gradient.colorAt(0.5);
```

### Encode and decode hex values

```dart
final hex = ColourCodec.toHex(const Color(0xFFF5746F)); // #FFF5746F
final color = ColourCodec.fromHex('#2E4EA8');
final pasted = ColourCodec.tryParseHex('f80'); // null when it is not a colour
```

## API Overview

- `ColourSelection`: the solid colour, the gradient, which of them is used, and a tint
- `GradientConfig` / `GradientStop`: gradient type, colours and stops, angle, centre, radius, sweep angles
- `ColourPalette` / `NamedGradient`: named collections
- `ColourLibrary`: recent colours, palettes and gradients
- `ColourPresets`: package-provided palettes and gradients
- `ColourTheory`: harmony calculators
- `ColourCodec`: hex conversion helpers
- `ColourStorageRepository`: optional on-device persistence

## Additional Information

- Source: https://github.com/just-unknown-dev/just-game-engine
- Package path: `packages/just_colours`
- Current version: `0.1.0`

Issues and improvements are welcome through the repository issue tracker.
