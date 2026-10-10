// On a Mac (macOS 15 or later):
//   swift make_glyph_heic.swift Logo_White_160.png Logo_AdaptiveGlyph.heic
// Or run automatically in GitHub Actions macOS runners via the included workflow.
// This is an experimental HEIC image with the minimum metadata shown by
// https://zenn.dev/noppe/scraps/e08ce9a5a2c355

import Foundation
import AppKit
import ImageIO
import UniformTypeIdentifiers

let args = CommandLine.arguments
let input = args.count > 1 ? args[1] : "Logo_White_160.png"
let output = args.count > 2 ? args[2] : "Logo_AdaptiveGlyph.heic"
let identifier = "E5DFB47A-B3A4-4EB1-BFE7-00EF3133DB82"
let description = "Winking smiling face logo with swept hair"

func main() throws {
    let src = URL(fileURLWithPath: input)
    let dest = URL(fileURLWithPath: output)
    guard let source = CGImageSourceCreateWithURL(src as CFURL, nil),
          let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        throw NSError(domain: "GlyphTest", code: 1, userInfo: [NSLocalizedDescriptionKey: "Can't read PNG"])
    }
    let metadata = CGImageMetadataCreateMutable()
    let ok = CGImageMetadataSetValueWithPath(
        metadata, nil, "tiff:DocumentName" as CFString, identifier as NSString
    )
    guard ok else { throw NSError(domain: "GlyphTest", code: 2, userInfo: [NSLocalizedDescriptionKey: "Metadata error"]) }
    _ = CGImageMetadataSetValueWithPath(
        metadata, nil, "dc:description" as CFString, description as NSString
    )
    let buffer = NSMutableData()
    guard let writer = CGImageDestinationCreateWithData(buffer, UTType.heic.identifier as CFString, 1, nil) else {
        throw NSError(domain: "GlyphTest", code: 3, userInfo: [NSLocalizedDescriptionKey: "No HEIC writer"])
    }
    CGImageDestinationAddImageAndMetadata(writer, cgImage, metadata, nil)
    guard CGImageDestinationFinalize(writer) else {
        throw NSError(domain: "GlyphTest", code: 4, userInfo: [NSLocalizedDescriptionKey: "Encoding failed"])
    }
    try (buffer as Data).write(to: dest, options: .atomic)
    // NSAdaptiveImageGlyph is available on macOS 15.0+.
    let glyph = NSAdaptiveImageGlyph(imageContent: buffer as Data)
    print("Wrote: \(dest.path) | bytes: \(buffer.length)")
    print("NSAdaptiveImageGlyph ID: \(glyph.contentIdentifier)")
    print("Description: \(glyph.contentDescription)")
    print("Recognized bytes: \(glyph.imageContent.count)")
    guard glyph.imageContent.count > 0 else {
        throw NSError(domain: "GlyphTest", code: 5, userInfo: [NSLocalizedDescriptionKey: "Apple did not recognize the glyph data"])
    }
}

do {
    try main()
} catch {
    fputs("ERROR: \(error.localizedDescription)\n", stderr)
    exit(1)
}
