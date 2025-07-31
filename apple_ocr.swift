#!/usr/bin/env swift

import Foundation
import Vision
import CoreImage

func extractText(from imagePath: String) async throws -> String {
    // Load the image
    guard let image = CIImage(contentsOf: URL(fileURLWithPath: imagePath)) else {
        throw NSError(domain: "OCRError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not load image"])
    }

    // Create text recognition request
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    request.automaticallyDetectsLanguage = true

    // Perform the request
    let handler = VNImageRequestHandler(ciImage: image, options: [:])
    try handler.perform([request])

    // Extract results
    guard let observations = request.results else {
        return ""
    }

    let recognizedStrings = observations.compactMap { observation in
        observation.topCandidates(1).first?.string
    }

    return recognizedStrings.joined(separator: "\n")
}

func printUsage() {
    print("Usage: apple_ocr <image_path>")
    print("Extracts text from images using Apple's Vision framework")
    print("")
    print("Examples:")
    print("  apple_ocr screenshot.png")
    print("  apple_ocr /path/to/image.jpg")
}

// Check command line arguments
guard CommandLine.arguments.count == 2 else {
    printUsage()
    exit(1)
}

let imagePath = CommandLine.arguments[1]

// Check if file exists
guard FileManager.default.fileExists(atPath: imagePath) else {
    fputs("Error: File not found: \(imagePath)\n", stderr)
    exit(1)
}

// Run OCR
Task {
    do {
        let extractedText = try await extractText(from: imagePath)
        if extractedText.isEmpty {
            fputs("No text found in image\n", stderr)
            exit(1)
        } else {
            print(extractedText)
        }
    } catch {
        fputs("Error: \(error.localizedDescription)\n", stderr)
        exit(1)
    }

    exit(0)
}