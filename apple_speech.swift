import Foundation
import Speech
import AVFoundation

@main
struct SpeechRecognitionTool {

    static func extractText(from audioPath: String) async throws -> String {
        // Check if speech recognition is available
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            throw NSError(domain: "SpeechError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Speech recognition not authorized"])
        }

        // Create speech recognizer
        guard let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) else {
            throw NSError(domain: "SpeechError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer not available"])
        }

        // Check if recognizer is available
        guard speechRecognizer.isAvailable else {
            throw NSError(domain: "SpeechError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer not available"])
        }

        // Load the audio file
        let audioURL = URL(fileURLWithPath: audioPath)

        // Create recognition request
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false
        request.taskHint = .dictation

        // Configure for better accuracy
        if #available(macOS 13.0, *) {
            request.addsPunctuation = true
            request.requiresOnDeviceRecognition = true  // Privacy: keep everything local
        }

        // Perform recognition
        return try await withCheckedThrowingContinuation { continuation in
            speechRecognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let result = result, result.isFinal {
                    continuation.resume(returning: result.bestTranscription.formattedString)
                }
            }
        }
    }

    static func requestSpeechPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    static func printUsage() {
        print("Usage: apple_speech <audio_file> [options]")
        print("Transcribes audio files using Apple's Speech framework")
        print("")
        print("Options:")
        print("  --language <code>    Language code (default: en-US)")
        print("  --format <format>    Output format: text, json (default: text)")
        print("  --metadata           Include metadata in output")
        print("")
        print("Examples:")
        print("  apple_speech recording.wav")
        print("  apple_speech meeting.m4a --language en-US --format json")
        print("")
        print("Note: This tool requires speech recognition permissions")
        print("      Run with --request-permission to set up permissions")
    }

    static func parseArguments() -> (audioPath: String?, language: String, format: String, includeMetadata: Bool, requestPermission: Bool) {
        let args = CommandLine.arguments
        var audioPath: String?
        var language = "en-US"
        var format = "text"
        var includeMetadata = false
        var requestPermission = false

        var i = 1
        while i < args.count {
            let arg = args[i]

            switch arg {
            case "--language":
                if i + 1 < args.count {
                    language = args[i + 1]
                    i += 1
                }
            case "--format":
                if i + 1 < args.count {
                    format = args[i + 1]
                    i += 1
                }
            case "--metadata":
                includeMetadata = true
            case "--request-permission":
                requestPermission = true
            case "--help", "-h":
                printUsage()
                exit(0)
            default:
                if !arg.hasPrefix("--") && audioPath == nil {
                    audioPath = arg
                }
            }
            i += 1
        }

        return (audioPath, language, format, includeMetadata, requestPermission)
    }

    static func outputResult(_ text: String, format: String, includeMetadata: Bool, audioPath: String) {
        switch format {
        case "json":
            var jsonOutput: [String: Any] = [
                "transcription": text,
                "success": true
            ]

            if includeMetadata {
                jsonOutput["audio_file"] = audioPath
                jsonOutput["timestamp"] = ISO8601DateFormatter().string(from: Date())
                jsonOutput["method"] = "Apple Speech Framework"
                jsonOutput["language"] = "en-US"  // TODO: Make this dynamic
            }

            if let jsonData = try? JSONSerialization.data(withJSONObject: jsonOutput, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
            } else {
                print("Error: Could not format JSON output")
            }

        default: // text format
            if includeMetadata {
                print("# Speech Recognition Transcription")
                print("# Audio: \(audioPath)")
                print("# Transcribed: \(Date())")
                print("# Method: Apple Speech Framework")
                print("")
            }
            print(text)
        }
    }

    static func main() async {
        let (audioPath, _, format, includeMetadata, requestPermission) = parseArguments()

        // Handle permission request
        if requestPermission {
            print("Requesting speech recognition permission...")
            let granted = await requestSpeechPermission()
            if granted {
                print("✅ Speech recognition permission granted")
                exit(0)
            } else {
                print("❌ Speech recognition permission denied")
                print("Please enable speech recognition in System Preferences > Security & Privacy > Privacy > Speech Recognition")
                exit(1)
            }
        }

        // Validate arguments
        guard let audioPath = audioPath else {
            printUsage()
            exit(1)
        }

        // Check if file exists
        guard FileManager.default.fileExists(atPath: audioPath) else {
            fputs("Error: Audio file not found: \(audioPath)\n", stderr)
            exit(1)
        }

        // Check permissions
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            fputs("Error: Speech recognition not authorized\n", stderr)
            fputs("Run with --request-permission to set up permissions\n", stderr)
            exit(1)
        }

        // Perform transcription
        do {
            let transcription = try await extractText(from: audioPath)

            if transcription.isEmpty {
                fputs("No speech detected in audio file\n", stderr)
                exit(1)
            } else {
                outputResult(transcription, format: format, includeMetadata: includeMetadata, audioPath: audioPath)
            }
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }
}