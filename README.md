# Custom face → Apple adaptive image glyph lab

This repository tests whether the **exact original face logo** can be copied into Apple Messages as **one inline emoji-like object**. It is not ASCII art or an attempt to register a new Unicode character.

## Run it from an iPhone (no Mac needed)

1. Open **[the test webpage](https://jrdn-r.github.io/ChatGPTs-Gay-Little-Experiment/)** in Safari. (It will only load after GitHub Pages has been enabled and the deployment workflow has succeeded.)
2. Tap **Select full line**, then use the iOS **Copy** menu. Alternatively try **Try copy** or **Copy rich HTML**.
3. Open an iMessage conversation, paste into the typing field, then send it to a second compatible iPhone.
4. Check whether the logo remains **inline like one emoji** or is converted to a normal picture or plain text. That's the actual pass/fail test.

### One-time GitHub Pages setting

The conversion runs automatically on every relevant push, but Pages sometimes needs one manual setup step:

- Open [repository Settings → Pages](https://github.com/JRDN-R/ChatGPTs-Gay-Little-Experiment/settings/pages).
- Under **Build and deployment**, set **Source = GitHub Actions** (not "Deploy from a branch").
- Save if prompted. Then open [Actions](https://github.com/JRDN-R/ChatGPTs-Gay-Little-Experiment/actions/workflows/build-glyph.yml) and use **Run workflow** if an earlier deployment failed.
- When the action succeeds, load the [iPhone test page](https://jrdn-r.github.io/ChatGPTs-Gay-Little-Experiment/).

No secret API key or Apple Developer account is required for this **browser experiment**. The public GitHub Pages site and logo files are publicly accessible.

## What GitHub Actions does

The workflow [`.github/workflows/build-glyph.yml`](.github/workflows/build-glyph.yml) performs:

1. Run `make_glyph_heic.swift` on a hosted **macOS 15** machine to encode `Logo_White_160.png` into `Logo_AdaptiveGlyph.heic`.
2. Call `NSAdaptiveImageGlyph(imageContent:)` to check whether Apple's text system recognizes the HEIC.
3. Upload a downloadable build artifact, named `experimental-apple-adaptive-glyph`.
4. Deploy `index.html` plus the image files to GitHub Pages.

The Swift conversion is an experimental application of an independent [developer finding](https://zenn.dev/noppe/scraps/e08ce9a5a2c355), which suggests a HEIC can be recognized if it has `tiff:DocumentName` metadata. Apple does not document arbitrary PNG-to-Genmoji creation as a general public feature.

**Critical limitation:** Recognition as `NSAdaptiveImageGlyph` by macOS does **not** prove that Safari can put that glyph onto the iOS clipboard, nor that Messages will retain it when pasted. The browser copy test is deliberately experimental.

## If Safari only pastes a normal image or text

The fallback is a **native iOS test app**, because native `UITextView` and `UIPasteboard` can handle attributed text containing the `NSAdaptiveImageGlyph` attribute. The source `LogoGlyphLab.swift` is included for this experiment. An installable signed iOS app requires an iOS build/signing and distribution route; downloading a .swift or .heic file onto an iPhone does not install one. No signed IPA/TestFlight app is being provided by this repository yet.

## Project files

| File | Purpose |
|---|---|
| `index.html` | iPhone-facing Safari test webpage |
| `.github/workflows/build-glyph.yml` | Generates HEIC and deploys webpage |
| `make_glyph_heic.swift` | Mac-compatible HEIC encoder and recognition check |
| `Logo_White_160.png` | Transparent 160×160 source for HEIC |
| `Logo_White_320.png` | Larger inline fallback image |
| `Logo_DarkInk_800.png` | Contrast preview on light background |
| `LogoGlyphLab.swift` | Experimental SwiftUI/UITextView iOS app source |
| `safari-copy-test.html` | Earlier minimal web copy trial |

## References

- [Apple: NSAdaptiveImageGlyph](https://developer.apple.com/documentation/uikit/nsadaptiveimageglyph)
- [Apple/WebKit adaptive image glyph tests](https://chromium.googlesource.com/external/github.com/WebKit/webkit/+/e78e1b72a759be2e387bf71c9652059c3d8d0363/Tools/TestWebKitAPI/Tests/WebKit/WKWebView/AdaptiveImageGlyph.mm)
- [Independent developer's HEIC metadata experiment](https://zenn.dev/noppe/scraps/e08ce9a5a2c355)

The goal is to **test and measure**, not claim that Apple's Messages app accepts user-built emoji as universal text characters.
