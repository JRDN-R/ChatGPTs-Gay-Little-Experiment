// LogoGlyphLab.swift
// iOS 18+ proof-of-concept. Create an iOS SwiftUI App in Xcode,
// replace the app's generated Swift file with this file,
// and add Logo_White_160.png to the Xcode target's Copy Bundle Resources.
// This experiments with PNG -> metadata-enriched HEIC -> NSAdaptiveImageGlyph.
// It does not use private APIs.

import SwiftUI
import UIKit
import ImageIO
import UniformTypeIdentifiers

@main
struct LogoGlyphLabApp: App {
    var body: some Scene {
        WindowGroup { LogoGlyphLabView() }
    }
}

enum GlyphLabError: LocalizedError {
    case missingPNG, invalidPNG, noDestination, metadataFailed, encodingFailed, invalidGlyph
    var errorDescription: String? {
        switch self {
        case .missingPNG: return "Logo_White_160.png must be added to Copy Bundle Resources."
        case .invalidPNG: return "The PNG could not be decoded into a CGImage."
        case .noDestination: return "This device could not create a HEIC image destination."
        case .metadataFailed: return "The glyph's tiff:DocumentName metadata could not be written."
        case .encodingFailed: return "HEIC encoding failed."
        case .invalidGlyph: return "Apple did not recognize the generated HEIC as an adaptive glyph."
        }
    }
}

@MainActor
enum LogoGlyphFactory {
    static let identifier = "E5DFB47A-B3A4-4EB1-BFE7-00EF3133DB82"
    static let description = "Winking smiling face logo with swept hair"

    static func create() throws -> (glyph: NSAdaptiveImageGlyph, data: Data, png: UIImage) {
        guard let sourceURL = Bundle.main.url(forResource: "Logo_White_160", withExtension: "png"),
              let pngData = try? Data(contentsOf: sourceURL) else {
            throw GlyphLabError.missingPNG
        }
        guard let image = UIImage(data: pngData), let cgImage = image.cgImage else {
            throw GlyphLabError.invalidPNG
        }

        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output, UTType.heic.identifier as CFString, 1, nil
        ) else { throw GlyphLabError.noDestination }

        let metadata = CGImageMetadataCreateMutable()
        guard CGImageMetadataSetValueWithPath(
            metadata, nil, "tiff:DocumentName" as CFString,
            identifier as NSString
        ) else { throw GlyphLabError.metadataFailed }
        // Apple-made Genmoji also carry a content description. This tag is optional
        // for our experiment, so we do not fail if ImageIO won't accept it.
        _ = CGImageMetadataSetValueWithPath(
            metadata, nil, "dc:description" as CFString,
            description as NSString
        )
        CGImageDestinationAddImageAndMetadata(destination, cgImage, metadata, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw GlyphLabError.encodingFailed
        }

        let data = output as Data
        let glyph = NSAdaptiveImageGlyph(imageContent: data)
        guard !glyph.imageContent.isEmpty, !glyph.contentIdentifier.isEmpty else {
            throw GlyphLabError.invalidGlyph
        }
        return (glyph, data, image)
    }
}

struct LogoGlyphLabView: View {
    @State private var glyph: NSAdaptiveImageGlyph?
    @State private var generatedHEIC: Data?
    @State private var originalPNG: UIImage?
    @State private var richText = NSAttributedString(string: "Build glyph to begin.")
    @State private var feedback = "Ready for the PNG → HEIC → native glyph test."
    @State private var exportedFile: URL?
    @State private var isSharing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        if let png = UIImage(named: "Logo_White_160") ?? originalPNG {
                            Image(uiImage: png)
                                .resizable().scaledToFit()
                                .frame(width: 100, height: 100)
                                .padding(8)
                                .background(Color(red: 0.10, green: 0.11, blue: 0.13))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Logo Glyph Lab").font(.title2.bold())
                            Text("Experimental adaptive image glyph for Messages")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                    Text(feedback).font(.callout)
                        .textSelection(.enabled)
                        .accessibilityIdentifier("glyphStatus")

                    Button("1. Build native image glyph") { createGlyph() }
                        .buttonStyle(.borderedProminent)

                    Text("2. Check rendering and use the native text-selection menu")
                        .font(.headline)
                    GlyphEditingView(attributedText: richText)
                        .frame(height: 100)
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .stroke(.gray.opacity(0.3), lineWidth: 1))
                    Text("Long-press the face above → Select All → Copy → paste in Messages. This tests Apple's own UITextView copying.")
                        .font(.footnote).foregroundStyle(.secondary)

                    Button("3. Copy glyph as flat RTFD") {
                        copyRichText(includePlainFallback: false)
                    }
                    .buttonStyle(.bordered)
                    .disabled(glyph == nil)

                    Button("4. Copy glyph with text fallback") {
                        copyRichText(includePlainFallback: true)
                    }
                    .buttonStyle(.bordered)
                    .disabled(glyph == nil)

                    Button("5. Copy PNG fallback") { copyPNG() }
                        .buttonStyle(.bordered)

                    Button("6. Share generated HEIC") { shareHEIC() }
                        .buttonStyle(.bordered)
                        .disabled(generatedHEIC == nil)

                    Text("This is an experiment, not an iMessage extension. Successful rendering inside this test app does NOT prove Messages accepts the clipboard representation.")
                        .font(.footnote).foregroundStyle(.secondary)
                    if let glyph {
                        Text("Identifier: \(glyph.contentIdentifier)")
                            .font(.caption2.monospaced()).textSelection(.enabled)
                        Text("Description: \(glyph.contentDescription)")
                            .font(.caption).textSelection(.enabled)
                        Text("HEIC bytes: \(glyph.imageContent.count)")
                            .font(.caption).textSelection(.enabled)
                    }
                }
                .padding()
            }
            .navigationTitle("Adaptive Glyph Test")
            .sheet(isPresented: $isSharing) {
                if let exportedFile { GlyphShareSheet(items: [exportedFile]) }
            }
        }
    }

    private func createGlyph() {
        do {
            let result = try LogoGlyphFactory.create()
            glyph = result.glyph
            generatedHEIC = result.data
            originalPNG = result.png
            let oneGlyph = NSAttributedString(
                adaptiveImageGlyph: result.glyph,
                attributes: [.font: UIFont.systemFont(ofSize: 32)]
            )
            richText = oneGlyph
            feedback = "Glyph built! ID \(result.glyph.contentIdentifier). Now try native Copy, then paste into Messages."
        } catch {
            feedback = "Build failed: \(error.localizedDescription)"
            glyph = nil
            generatedHEIC = nil
        }
    }

    private func copyRichText(includePlainFallback: Bool) {
        guard let glyph else { return }
        let oneGlyph = NSAttributedString(
            adaptiveImageGlyph: glyph,
            attributes: [.font: UIFont.systemFont(ofSize: 25)]
        )
        do {
            let data = try oneGlyph.data(
                from: NSRange(location: 0, length: oneGlyph.length),
                documentAttributes: [.documentType: NSAttributedString.DocumentType.rtfd]
            )
            var item: [String: Any] = [UTType.flatRTFD.identifier: data]
            if includePlainFallback {
                item[UTType.utf8PlainText.identifier] = "[face logo]"
            }
            UIPasteboard.general.items = [item]
            feedback = "Copied \(data.count) bytes as flattened RTFD\(includePlainFallback ? " with plain fallback" : " only"). Paste into Messages to test."
        } catch {
            feedback = "RTFD export failed: \(error.localizedDescription)"
        }
    }

    private func copyPNG() {
        if let png = originalPNG ?? UIImage(named: "Logo_White_160") {
            UIPasteboard.general.image = png
            feedback = "Copied PNG fallback. This is not a native adaptive image glyph."
        } else {
            feedback = "Logo PNG is missing from app resources."
        }
    }

    private func shareHEIC() {
        guard let generatedHEIC else { return }
        do {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("Logo_AdaptiveGlyph.heic")
            try generatedHEIC.write(to: url, options: .atomic)
            exportedFile = url
            isSharing = true
        } catch {
            feedback = "HEIC save failed: \(error.localizedDescription)"
        }
    }
}

struct GlyphEditingView: UIViewRepresentable {
    let attributedText: NSAttributedString

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.supportsAdaptiveImageGlyph = true
        view.font = .systemFont(ofSize: 32)
        view.backgroundColor = .secondarySystemBackground
        view.isEditable = true
        view.isSelectable = true
        view.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)
        view.layer.cornerRadius = 10
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        if !view.attributedText.isEqual(to: attributedText) {
            view.attributedText = attributedText
        }
    }
}

struct GlyphShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
