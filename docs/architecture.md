# SahiFile Architecture & Technical Design

## 1. Clean Architecture Overview
SahiFile follows a feature-first Clean Architecture pattern designed for maintainability, high testability, and clear separation of concerns:

```
lib/
├── core/                         # Cross-cutting foundational modules
│   ├── constants/                # App-wide constants, file size thresholds
│   ├── errors/                   # AppError typed error model with actionable hints
│   ├── localization/             # AppStrings (Bilingual English & Hindi support)
│   ├── models/                   # Result<T> sealed class functional monad
│   ├── utils/                    # FileUtils (sandboxed workspace) & Formatters
│   └── widgets/                  # GlassAppBar, GlassSurface, AppDialog, AppButton
├── app/                          # Application bootstrap & dependency injection
│   ├── app.dart                  # Root MaterialApp with dynamic theme switcher
│   ├── providers.dart            # Riverpod 3 NotifierProvider registrations
│   └── theme/                    # Glass UI design tokens (light and dark modes)
└── features/                     # Feature modules
    ├── home/                     # Dashboard with quick actions & recent history
    ├── tools/                    # Tool gallery
    ├── photo_editor/             # Crop, resize, iterative KB search, EXIF baking
    │   ├── domain/               # PhotoEditParams, PhotoProcessResult
    │   ├── data/                 # ImageProcessingService (Dart isolates)
    │   └── presentation/         # PhotoSetupScreen, CropEditorScreen, PhotoResultScreen
    ├── pdf_tools/                # Images-to-PDF, PDF Merge, PDF Optimizer
    │   ├── domain/               # ImagesToPdfParams, PdfToolResult
    │   ├── data/                 # PdfService (pure Dart pdf & syncfusion_flutter_pdf)
    │   └── presentation/         # ImagesToPdfScreen, PdfMergeScreen, PdfResultScreen
    ├── presets/                  # Preconfigured & user-defined dimensions
    ├── history/                  # Recent files tracker, safe deletion, search
    └── settings/                 # Appearance, Language, Cache cleanup, Legal
```

## 2. File Processing Safety & Sandboxing
- **Non-Destructive Guarantee**: Original input files are opened read-only. SahiFile immediately creates an internal working copy in `app_flutter/formmate_cache`.
- **Isolate Offloading**: CPU-intensive operations (JPEG iterative compression, image rotation, and bicubic resampling) execute inside background Dart isolates via `compute()`, ensuring 60fps UI responsiveness without frame drops.
- **Iterative Target KB Search Algorithm**:
  1. Decodes and bakes EXIF orientation.
  2. Applies pixel cropping and rotation.
  3. Resizes to exact target width and height.
  4. Flattens transparent PNG alpha channels over a user-selected background color (preventing unwanted black backgrounds in JPEGs).
  5. Performs bounded binary search on quality factors ($Q \in [15, 96]$) measuring actual encoded bytes until the file is strictly $\le$ user's target byte limit.
  6. If even at $Q=15$ the file exceeds target KB, truthful warnings explain that pixel dimensions must be scaled down.

## 3. PDF Engine Choices & Trade-offs
- **PDF Creation**: Built with `pdf` package (`pw.Document`) for high-fidelity vector rendering, configurable page sizes (A4, Letter, Fit to image), and margins.
- **PDF Merging & Compression**: Uses `syncfusion_flutter_pdf` entirely on-device. Encrypted documents are gracefully caught with actionable unlocking guidance.

## 4. State Management with Riverpod 3
- State is decoupled from widgets using modern `Notifier` and `NotifierProvider`.
- All repository and service interfaces are injectable for unit testing with mocks.
