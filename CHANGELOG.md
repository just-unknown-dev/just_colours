## 0.1.0

Initial release: The picker, redesigned.

* **One picker, two windows.** `ColourPickerPanel` is the picker itself;
  `ColourPopover.show` opens it beside a field (a click outside applies,
  Escape cancels) and `JustColourDialog.show` in the middle of the screen.
  Both take `onChanged` to show a colour live as it is dragged, a
  `builder` to put a theme round it, and draw only from the ambient
  `Theme`.
* **Solid or Gradient is what you get.** The switch at the top replaces
  the tabs and the "Use Gradient in result" toggle, which let a gradient
  be edited and a solid colour come back.
* **Colours edited in place**: a saturation/brightness square, hue and
  opacity strips, and Hex, RGB, HSL or HSV numbers; a pasted `#RGB`,
  `#RRGGBB` or `#AARRGGBB` is read. No second dialog.
* **Gradients with any number of colours.** A stop bar adds, moves and
  removes them (click, drag, drag off or Delete); the preview has handles
  for a linear gradient's direction, a radial one's centre and size, and a
  sweep's centre, start and end. Reverse, space evenly, and what lies past
  the ends (extend, repeat, mirror, clear).
* **Tint.** `ColourSelection.tint` is multiplied over a gradient; the
  picker shows it when asked (`showTint`), and its preview is what will be
  drawn.
* **Swatches**: recent colours, palettes, labelled harmonies (each colour
  once) and gradients, with "To gradient" from a palette or harmony.
* **`ColourLibrary`** keeps recent colours, palettes and gradients and says
  when each changes, so they can be kept in different places.
  `ColourStorageRepository.loadLibrary()` keeps one on the device.
* **Eyedropper** given a `ColourSampler` that reads the screen.
* Fixed: swapping a gradient's ends dropped every colour after the second;
  the stop count shown was always two; stops left unmatched by colours
  broke the gradient (`copyWith` now drops them); a sweep's angles were not
  kept; a negative angle read as 0; harmony suggestions repeated the base
  colour; the preview text could not be read on light colours.
* Added: `GradientStop`, `GradientConfig.stopList` / `withStopList` /
  `reversed` / `evenlySpaced` / `colorAt`, `startAngle` / `endAngle`,
  equality on the models, `NamedGradient`, `ColourTheory.harmonies` and
  `shades`, `ColourCodec.tryParseHex`.