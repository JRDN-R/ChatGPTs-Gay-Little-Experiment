# Winking face logo → Apple adaptive image glyph experiment

This kit uses the **actual supplied logo**. No text-art reconstruction or AI redraw is involved.

## Fastest test on the iPhone (no Mac, Xcode, or GitHub required)

1. Open `Logo_White_800.png` (or the dark-ink variation) in Photos.
2. Long press the face in the photo; choose **Add Sticker**.
3. Open Messages and insert the saved sticker using the **Stickers section of the emoji keyboard** while typing a sentence.
4. See whether it is inserted inline. A sticker is not guaranteed to be encoded as a native `NSAdaptiveImageGlyph` even when it is displayed inline.

The image files contain real transparency. White line-art is intended primarily for dark backgrounds; dark-ink variation is for light backgrounds. The exact outlines are retained.

## Native NSAdaptiveImageGlyph test (experimental)

This kit includes `LogoGlyphLab.swift`, which uses the public APIs ImageIO, UIKit, and UniformTypeIdentifiers to:

1. Load `Logo_White_160.png`.
2. Encode HEIC with XMP metadata, including a stable `tiff:DocumentName` identifier.
3. Call `NSAdaptiveImageGlyph(imageContent:)` and confirm the API does not discard the data.
4. Insert the glyph in a `UITextView` with `supportsAdaptiveImageGlyph = true`.
5. Test **three** ways of copying: native UITextView selection, flat RTFD rich-only pasteboard, flat RTFD plus text fallback.
6. Export the generated HEIC for inspection.

**To run on iPhone:** On a Mac running Xcode 16 or later, create a new SwiftUI iOS App (minimum iOS 18), replace the generated App file with `LogoGlyphLab.swift`, and add `Logo_White_160.png` as a regular bundled resource (check the app target membership). Build and run on an iPhone. Test copying the face from the app into Messages. 

The native test app is **not** a signed/installable IPA. It requires a build/signing environment to deploy to iPhone. The code has not been compiled or tested here on an Apple device.

## Generate metadata-enriched HEIC in a Mac or GitHub Actions

On a Mac running macOS 15 or newer:

```sh
swift make_glyph_heic.swift Logo_White_160.png Logo_AdaptiveGlyph.heic
```

This Mac script will attempt to validate the result using `NSAdaptiveImageGlyph` itself. It must run on Apple OS APIs. As an alternative, the included `.github/workflows/build-glyph.yml` can generate it in GitHub Actions with a `macos-15` runner. Upload the kit files to a **new repository**, then run the workflow from the Actions tab; download the resulting `experimental-adaptive-glyph` artifact. The example workflow assumes the root of that repository contains `Logo_White_160.png`, `make_glyph_heic.swift`, and the `.github` directory.

You can place `Logo_AdaptiveGlyph.heic` alongside `safari-copy-test.html` and `Logo_White_320.png` on static HTTPS hosting (such as GitHub Pages) to try the `<picture><source type="image/x-apple-adaptive-glyph">` markup in Safari. Use long-press / Select All / Copy to see how Messages handles the result. **This clipboard behavior is experimental and cannot be confirmed from this environment.**

## Why this is plausible, but unconfirmed

- Apple documents that `NSAdaptiveImageGlyph` handles inline images with metadata and can serialize through rich-text formats.
- A 2024 independent experiment by `noppe` showed that metadata-enriched HEIC generated from an ordinary PNG can be recognized as `NSAdaptiveImageGlyph`; a `tiff:DocumentName` UUID appeared sufficient in their test. This behavior is **not a documented API contract**.
- A HEIC image by itself is not a universal Unicode symbol. Even if Messages accepts it, sharing outside rich-text-aware apps may fall back to an image or other representation.
- The Mac GitHub Actions workflow and iOS Swift sample were prepared but not executed here; results on iOS 27 remain unverified.

Sources:
- https://developer.apple.com/documentation/uikit/nsadaptiveimageglyph
- https://developer.apple.com/videos/play/wwdc2024/10220/
- https://zenn.dev/noppe/scraps/e08ce9a5a2c355
- https://chromium.googlesource.com/external/github.com/WebKit/webkit/+/e78e1b72a759be2e387bf71c9652059c3d8d0363/Tools/TestWebKitAPI/Tests/WebKit/WKWebView/AdaptiveImageGlyph.mm
