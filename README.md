# imagePreview

A minimal macOS image viewer — open one image, then use ← / → to browse the rest of the folder.

Built with SwiftUI + AppKit. Replaces the awkward “open one file, stuck on one file” feel of Preview for day-to-day browsing.

## Features

- **Folder association**: opening a file builds a same-directory image list; ← / → moves previous / next (stops at ends)
- **Single window**: opening another image replaces the current one — no window spam
- **Display modes**: toolbar buttons for Fit / Fill / Actual size / Stretch (no free zoom/drag resize)
- **Rotation**: display-only; kept when switching images

No crop, edit, delete, free zoom, or export.

## Requirements

- macOS 14+
- Xcode 16+ (Swift 6)

## Build & run

```bash
xcodegen generate
open imagePreview.xcodeproj
```

Or from the CLI:

```bash
xcodegen generate
xcodebuild -scheme imagePreview -configuration Release -derivedDataPath build
open build/Build/Products/Release/imagePreview.app
```

## Shortcuts

| Key | Action |
|-----|--------|
| ← / → | Previous / next image |
| 0 | Fit |
| F | Fill |
| 1 | Actual size |
| S | Stretch |
| R / Shift+R | Rotate CW / CCW |
| ⌘O | Open… |

## Supported formats

`jpg` `jpeg` `png` `heic` `heif` `webp` `gif` `tif` `tiff` `bmp`

## License

MIT
