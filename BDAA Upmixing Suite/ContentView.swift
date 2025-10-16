import Foundation
import AVFoundation
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Color Scheme

extension Color {
    static let appBackground = Color(red: 0.05, green: 0.08, blue: 0.15)  // Very dark blue
    static let appSecondary = Color(red: 0.08, green: 0.12, blue: 0.20)   // Slightly lighter blue
    static let appAccent = Color(red: 0.2, green: 0.4, blue: 0.8)         // Bright blue accent
    static let appText = Color(red: 0.9, green: 0.9, blue: 0.95)          // Light text
    static let appTextSecondary = Color(red: 0.6, green: 0.6, blue: 0.7)  // Secondary text
    static let appBorder = Color(red: 0.15, green: 0.2, blue: 0.3)        // Border color
}

// MARK: - Enums and Structs

enum AudioFormat: String, CaseIterable {
    case pcm = "PCM"
    case truehd = "TrueHD"
    case dts = "DTS"
    case thx = "THX"
    
    
    var channelLayout: String {
        switch self {
        case .pcm:
            return "varies"  // Depends on channel layout selection
        case .truehd:
            return "varies"  // Depends on channel layout selection
        case .dts:
            return "varies"  // Depends on channel layout selection
        case .thx:
            return "varies"  // Depends on channel layout selection
        }
    }
    
    var displayName: String {
        return self.rawValue
    }
}

enum ChannelLayout: String, CaseIterable {
    case pcm20 = "2.0 Stereo"
    case pcm51 = "5.1 Surround"
    case pcm71 = "7.1 Surround"
    case spatial71 = "7.1 Spatial Enhanced"
    case atmosReady714 = "7.1.4 Atmos Ready"
    case enhanced71 = "7.1 Enhanced"
    case xReady714 = "7.1.4 :X Ready"
    case thx71 = "7.1 THX Certified"
    case thx714 = "7.1.4 THX Spatial Audio"
    
    var channelCount: String {
        switch self {
        case .pcm20:
            return "2.0"
        case .pcm51:
            return "5.1"
        case .pcm71, .spatial71, .enhanced71, .thx71:
            return "7.1"
        case .atmosReady714, .xReady714, .thx714:
            return "7.1.4"
        }
    }
    
    var displayName: String {
        return self.rawValue
    }
    
    static func options(for format: AudioFormat) -> [ChannelLayout] {
        switch format {
        case .pcm:
            return [.pcm20, .pcm51, .pcm71]
        case .truehd:
            return [.spatial71, .atmosReady714]
        case .dts:
            return [.enhanced71, .xReady714]
        case .thx:
            return [.thx71, .thx714]
        }
    }
}

enum AudioQuality: String, CaseIterable {
    case cd = "16/48"
    case standard = "24/48"
    case highRes = "24/96"
    case audiophile = "24/192"
    case maxBit = "32/48"
    case maxBitHigh = "32/96"
    case maxBitUltra = "32/192"
    
    var sampleRate: String {
        switch self {
        case .cd, .standard, .maxBit: return "48000"
        case .highRes, .maxBitHigh: return "96000"
        case .audiophile, .maxBitUltra: return "192000"
        }
    }
    
    var bitDepth: String {
        switch self {
        case .cd: return "s16"
        case .standard, .highRes, .audiophile: return "s32"  // FFmpeg uses s32 for 24-bit
        case .maxBit, .maxBitHigh, .maxBitUltra: return "s32"  // 32-bit
        }
    }
    
    var displayName: String {
        switch self {
        case .cd: return "16-bit / 48 kHz"
        case .standard: return "24-bit / 48 kHz"
        case .highRes: return "24-bit / 96 kHz"
        case .audiophile: return "24-bit / 192 kHz"
        case .maxBit: return "32-bit / 48 kHz"
        case .maxBitHigh: return "32-bit / 96 kHz"
        case .maxBitUltra: return "32-bit / 192 kHz"
        }
    }
}

enum FileFormat: String, CaseIterable {
    case flac = "FLAC"
    case alac = "ALAC"
    case wav = "WAV"
    case aiff = "AIFF"
    case m2ts = "M2TS"
    case mka = "MKA"
    case dts = "DTS"
    case truehd = "TrueHD"
    
    var fileExtension: String {
        switch self {
        case .flac: return "flac"
        case .alac: return "m4a"
        case .wav: return "wav"
        case .aiff: return "aiff"
        case .m2ts: return "m2ts"
        case .mka: return "mka"
        case .dts: return "dts"
        case .truehd: return "thd"
        }
    }
    
    var ffmpegCodec: String {
        switch self {
        case .flac: return "flac"
        case .alac: return "alac"
        case .wav: return "pcm_s32le"
        case .aiff: return "pcm_s32be"
        case .m2ts: return "pcm_bluray"
        case .mka: return "pcm_s32le"
        case .dts: return "dca"
        case .truehd: return "truehd"
        }
    }
    
    func isCompatible(with audioFormat: AudioFormat) -> Bool {
        switch audioFormat {
        case .pcm:
            return [.flac, .alac, .wav, .aiff].contains(self)
        case .truehd:
            return self == .truehd
        case .dts:
            return self == .dts
        case .thx:
            return [.wav, .mka].contains(self)
        }
    }
}

enum FileStatus: String {
    case pending = "Pending"
    case processing = "Processing..."
    case upmixed = "Upmixed"
    case failed = "Failed"
    case cancelled = "Cancelled"

    var color: Color {
        switch self {
        case .pending: return .secondary
        case .processing: return .accentColor
        case .upmixed: return .green
        case .failed: return .red
        case .cancelled: return .orange
        }
    }
}

enum UpmixError: LocalizedError {
    case ffmpegNotFound
    case processFailed(String)
    case operationCancelled
    case bookmarkFailed

    var errorDescription: String? {
        switch self {
        case .ffmpegNotFound:
            return "FFmpeg executable not found in the app bundle."
        case .processFailed(let message):
            return "The upmix operation failed: \(message)"
        case .operationCancelled:
            return "The upmix operation was cancelled."
        case .bookmarkFailed:
            return "Failed to create a security-scoped bookmark for file access."
        }
    }
}

struct BookmarkedURL: Identifiable {
    let id = UUID()
    let bookmarkData: Data
    let originalURL: URL
}

struct AudioFile: Identifiable {
    let id = UUID()
    let bookmarkedURL: BookmarkedURL
    var status: FileStatus = .pending
    
    var url: URL {
        // Try to resolve security-scoped bookmark first
        var isStale = false
        if let resolvedURL = try? URL(resolvingBookmarkData: bookmarkedURL.bookmarkData,
                                     options: .withSecurityScope,
                                     relativeTo: nil,
                                     bookmarkDataIsStale: &isStale) {
            if isStale {
                print("Warning: Bookmark data is stale for \(bookmarkedURL.originalURL.lastPathComponent)")
            }
            return resolvedURL
        }
        
        // Try to resolve without security scope as fallback
        if let resolvedURL = try? URL(resolvingBookmarkData: bookmarkedURL.bookmarkData,
                                     options: [],
                                     relativeTo: nil,
                                     bookmarkDataIsStale: &isStale) {
            print("Using non-security-scoped bookmark resolution for \(bookmarkedURL.originalURL.lastPathComponent)")
            return resolvedURL
        }
        
        // Final fallback to original URL
        print("Warning: Falling back to original URL for \(bookmarkedURL.originalURL.lastPathComponent)")
        return bookmarkedURL.originalURL
    }
}

// MARK: - AudioUpmixer Class

@MainActor
class AudioUpmixer: ObservableObject {
    @Published var files: [AudioFile] = []
    @Published var isUpmixing = false
    @Published var progress: Double = 0.0
    @Published var status: String = "Ready"
    @Published var errorMessage: String?
    @Published var outputDirectory: BookmarkedURL?
    @Published var selectedFormat: AudioFormat = .pcm
    @Published var selectedQuality: AudioQuality = .standard
    @Published var selectedChannelLayout: ChannelLayout = .pcm51
    @Published var selectedFileFormat: FileFormat = .flac
    @Published var useAISeparation: Bool = false

    private var ffmpegPath: String?
    private var currentProcess: Process?
    private var isCancelled = false

    init() {
        // Try to find FFmpeg in multiple locations
        self.ffmpegPath = findFFmpegPath()
        
        if let path = ffmpegPath {
            status = "Ready (FFmpeg found at \(path))"
        } else {
            status = "FFmpeg not found - please install FFmpeg"
            errorMessage = "FFmpeg is required for audio processing. Install it via Homebrew: brew install ffmpeg"
        }
    }
    
    private func findFFmpegPath() -> String? {
        // First try the app bundle
        if let bundlePath = Bundle.main.path(forResource: "ffmpeg", ofType: nil) {
            return bundlePath
        }
        
        // Try common system locations
        let commonPaths = [
            "/opt/homebrew/bin/ffmpeg",     // Homebrew on Apple Silicon
            "/usr/local/bin/ffmpeg",        // Homebrew on Intel
            "/usr/bin/ffmpeg",              // System install
            "/opt/local/bin/ffmpeg"         // MacPorts
        ]
        
        for path in commonPaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        // Try to find ffmpeg in PATH
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        task.arguments = ["ffmpeg"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !path.isEmpty {
                    return path
                }
            }
        } catch {
            print("Failed to search for ffmpeg in PATH: \(error)")
        }
        
        return nil
    }

    // MARK: - Public Methods

    func setOutputDirectory(url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            handleError(UpmixError.processFailed("Could not access directory: \(url.path). This may be due to app sandbox restrictions."))
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            self.outputDirectory = BookmarkedURL(bookmarkData: bookmarkData, originalURL: url)
        } catch {
            // Try without security scope as fallback
            do {
                let bookmarkData = try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
                self.outputDirectory = BookmarkedURL(bookmarkData: bookmarkData, originalURL: url)
                print("Warning: Using non-security-scoped bookmark for output directory")
            } catch {
                handleError(UpmixError.processFailed("Failed to create bookmark for directory: \(error.localizedDescription)"))
            }
        }
    }
    
    func addFile(url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            handleError(UpmixError.processFailed("Could not access file: \(url.lastPathComponent). This may be due to app sandbox restrictions."))
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            let bookmarkedURL = BookmarkedURL(bookmarkData: bookmarkData, originalURL: url)
            
            if !files.contains(where: { $0.bookmarkedURL.originalURL == url }) {
                files.append(AudioFile(bookmarkedURL: bookmarkedURL))
            }
        } catch {
            // Try without security scope as fallback
            do {
                let bookmarkData = try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
                let bookmarkedURL = BookmarkedURL(bookmarkData: bookmarkData, originalURL: url)
                
                if !files.contains(where: { $0.bookmarkedURL.originalURL == url }) {
                    files.append(AudioFile(bookmarkedURL: bookmarkedURL))
                    print("Warning: Using non-security-scoped bookmark for file: \(url.lastPathComponent)")
                }
            } catch {
                handleError(UpmixError.processFailed("Failed to create bookmark for file: \(error.localizedDescription)"))
            }
        }
    }

    func clearFiles() {
        guard !isUpmixing else { return }
        files.removeAll()
        resetStatus()
    }

    func startUpmixing() {
        guard !files.isEmpty, !isUpmixing else { return }
        guard ffmpegPath != nil else {
            handleError(UpmixError.ffmpegNotFound)
            return
        }
        guard outputDirectory != nil else {
            handleError(UpmixError.processFailed("Please select an output directory first."))
            return
        }

        isUpmixing = true
        isCancelled = false
        resetStatus()
        status = "Starting upmix..."

        Task {
            await processFiles()
            
            if !isCancelled {
                status = "Upmixing complete."
            }
            isUpmixing = false
        }
    }
    
    func cancelUpmixing() {
        isCancelled = true
        currentProcess?.terminate()
        status = "Cancelling..."
    }

    // MARK: - Private Methods

    private func processFiles() async {
        let totalFiles = files.count
        for i in 0..<files.count {
            if isCancelled {
                await handleCancellation(from: i)
                break
            }
            
            let file = files[i]
            
            guard file.url.startAccessingSecurityScopedResource() else {
                await updateFileStatus(at: i, to: .failed)
                handleError(UpmixError.processFailed("Could not access file at \(file.bookmarkedURL.originalURL.lastPathComponent)"))
                continue
            }
            
            await updateFileStatus(at: i, to: .processing, message: "Upmixing \(file.bookmarkedURL.originalURL.lastPathComponent)...")

            do {
                try await upmix(file: file)
                await updateFileStatus(at: i, to: .upmixed)
            } catch {
                if isCancelled {
                    await handleCancellation(from: i)
                    break
                }
                await updateFileStatus(at: i, to: .failed)
                handleError(error)
                break
            }
            
            file.url.stopAccessingSecurityScopedResource()
            
            progress = Double(i + 1) / Double(totalFiles)
        }
    }

    private func upmix(file: AudioFile) async throws {
        guard let ffmpegPath = ffmpegPath else { throw UpmixError.ffmpegNotFound }
        guard let outputDir = outputDirectory else { throw UpmixError.processFailed("Output directory not set.") }

        var isStale = false
        var resolvedOutputURL: URL?
        
        // Try security-scoped bookmark first
        resolvedOutputURL = try? URL(resolvingBookmarkData: outputDir.bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
        
        // Fallback to non-security-scoped
        if resolvedOutputURL == nil {
            resolvedOutputURL = try? URL(resolvingBookmarkData: outputDir.bookmarkData, options: [], relativeTo: nil, bookmarkDataIsStale: &isStale)
        }
        
        // Final fallback to original URL
        if resolvedOutputURL == nil {
            resolvedOutputURL = outputDir.originalURL
        }
        
        guard let outputDirURL = resolvedOutputURL else {
            throw UpmixError.processFailed("Could not resolve output directory URL")
        }
        
        guard outputDirURL.startAccessingSecurityScopedResource() else {
            throw UpmixError.processFailed("Could not access output directory.")
        }
        defer { outputDirURL.stopAccessingSecurityScopedResource() }

        let channelLayoutDescription: String
        switch selectedFormat {
        case .truehd, .dts:
            channelLayoutDescription = selectedChannelLayout.channelCount
        case .thx:
            channelLayoutDescription = "THX-\(selectedChannelLayout.channelCount)"
        case .pcm:
            channelLayoutDescription = selectedChannelLayout.channelCount
        }
        let outputFileName = file.bookmarkedURL.originalURL.deletingPathExtension().lastPathComponent + "_\(channelLayoutDescription).\(selectedFileFormat.fileExtension)"
        let outputURL = outputDirURL.appendingPathComponent(outputFileName)
        
        // Check if AI separation is enabled for 7.1.4 formats
        if useAISeparation && [ChannelLayout.atmosReady714, .xReady714, .thx714].contains(selectedChannelLayout) {
            do {
                try await upmixWithAI(file: file, outputURL: outputURL, outputDirURL: outputDirURL, ffmpegPath: ffmpegPath)
            } catch {
                // If AI processing fails, fall back to standard processing with a warning
                await MainActor.run {
                    self.status = "AI processing unavailable - using standard processing..."
                }
                print("AI processing failed, falling back to standard: \(error.localizedDescription)")
                try await upmixStandard(file: file, outputURL: outputURL, ffmpegPath: ffmpegPath)
            }
        } else {
            try await upmixStandard(file: file, outputURL: outputURL, ffmpegPath: ffmpegPath)
        }
    }
    
    private func upmixStandard(file: AudioFile, outputURL: URL, ffmpegPath: String) async throws {
        let filter = createFFmpegFilter(for: selectedFormat, channelLayout: selectedChannelLayout, useAI: false)
        var arguments = ["-i", file.url.path, "-vn"]
        
        // Add format-specific arguments
        switch selectedFormat {
        case .pcm:
            arguments += [
                "-af", filter,
                "-c:a", selectedFileFormat.ffmpegCodec,
                "-sample_fmt", selectedQuality.bitDepth,
                "-ar", selectedQuality.sampleRate
            ]
            
        case .truehd:
            // TrueHD format has fixed requirements
            arguments += [
                "-af", filter,
                "-c:a", selectedFileFormat.ffmpegCodec,
                "-ar", "48000",  // TrueHD standard is 48kHz
                "-strict", "experimental"
            ]
            
        case .dts:
            // DTS format has fixed requirements
            arguments += [
                "-af", filter,
                "-c:a", selectedFileFormat.ffmpegCodec,
                "-b:a", "1536k",
                "-ar", "48000",  // DTS standard is 48kHz
                "-strict", "experimental"
            ]
            
        case .thx:
            // THX LPCM format with enforced 24-bit/96kHz processing
            arguments += [
                "-af", filter,
                "-c:a", selectedFileFormat.ffmpegCodec,
                "-sample_fmt", "s32",  // 24-bit (stored as s32 in FFmpeg)
                "-ar", "96000"  // THX requires 96kHz sample rate
            ]
        }
        
        arguments += ["-y", outputURL.path]

        currentProcess = Process()
        currentProcess?.executableURL = URL(fileURLWithPath: ffmpegPath)
        currentProcess?.arguments = arguments

        let errorPipe = Pipe()
        currentProcess?.standardError = errorPipe

        do {
            try currentProcess?.run()
            currentProcess?.waitUntilExit()

            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorOutput = String(data: errorData, encoding: .utf8) ?? ""

            if currentProcess?.terminationStatus != 0 {
                if isCancelled {
                    throw UpmixError.operationCancelled
                } else {
                    throw UpmixError.processFailed(errorOutput)
                }
            }
        } catch {
            throw UpmixError.processFailed(error.localizedDescription)
        }
    }
    
    private func upmixWithAI(file: AudioFile, outputURL: URL, outputDirURL: URL, ffmpegPath: String) async throws {
        // Run Demucs separation first
        await MainActor.run {
            self.status = "Running AI source separation..."
        }
        
        let stemsDir: URL
        do {
            stemsDir = try await runDemucsseparation(inputFile: file.url, outputDir: outputDirURL)
        } catch {
            // If Demucs fails, throw a more specific error to trigger fallback
            throw UpmixError.processFailed("AI separation not available: \(error.localizedDescription)")
        }
        
        // Verify stems exist
        let stemFiles = [
            stemsDir.appendingPathComponent("vocals.wav"),
            stemsDir.appendingPathComponent("drums.wav"),
            stemsDir.appendingPathComponent("bass.wav"),
            stemsDir.appendingPathComponent("other.wav")
        ]
        
        for stemFile in stemFiles {
            if !FileManager.default.fileExists(atPath: stemFile.path) {
                throw UpmixError.processFailed("Missing stem file: \(stemFile.lastPathComponent)")
            }
        }
        
        // Create FFmpeg arguments for AI processing
        await MainActor.run {
            self.status = "Creating enhanced surround mix from stems..."
        }
        
        let filter = createFFmpegFilter(for: selectedFormat, channelLayout: selectedChannelLayout, useAI: true)
        var arguments: [String] = []
        
        // Add all stem files as inputs
        for stemFile in stemFiles {
            arguments += ["-i", stemFile.path]
        }
        
        arguments += ["-vn"]
        
        // Add format-specific arguments
        switch selectedFormat {
        case .truehd:
            arguments += [
                filter,
                "-c:a", selectedFileFormat.ffmpegCodec,
                "-ar", "48000",
                "-strict", "experimental"
            ]
        case .dts:
            arguments += [
                filter,
                "-c:a", selectedFileFormat.ffmpegCodec,
                "-ar", "48000"
            ]
        case .thx:
            arguments += [
                filter,
                "-c:a", selectedFileFormat.ffmpegCodec,
                "-sample_fmt", "s32",  // THX requires 24-bit
                "-ar", "96000"  // THX requires 96kHz
            ]
        default:
            // This shouldn't happen as AI is only for 7.1.4 formats
            throw UpmixError.processFailed("AI processing not supported for this format")
        }
        
        arguments += [outputURL.path]
        
        // Run FFmpeg with the stems
        currentProcess = Process()
        currentProcess?.executableURL = URL(fileURLWithPath: ffmpegPath)
        currentProcess?.arguments = arguments
        
        let errorPipe = Pipe()
        currentProcess?.standardError = errorPipe
        
        do {
            try currentProcess?.run()
            currentProcess?.waitUntilExit()
            
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
            
            if currentProcess?.terminationStatus != 0 {
                if isCancelled {
                    throw UpmixError.operationCancelled
                } else {
                    throw UpmixError.processFailed("AI upmix failed: \(errorOutput)")
                }
            }
        } catch {
            throw UpmixError.processFailed("AI upmix failed: \(error.localizedDescription)")
        }
        
        // Clean up temporary stems directory
        try? FileManager.default.removeItem(at: stemsDir.deletingLastPathComponent())
    }
    
    private func createFFmpegFilter(for format: AudioFormat, channelLayout: ChannelLayout = .spatial71, useAI: Bool = false) -> String {
        switch format {
        case .pcm:
            // PCM processing based on channel layout
            switch channelLayout {
            case .pcm20:
                // Simple stereo (no upmixing needed)
                return "aformat=channel_layouts=stereo"
            case .pcm51:
                // Enhanced stereo to 5.1 upmixing with spatial processing
                return "extrastereo=m=2.5,haas,dynaudnorm=f=150,surround"
            case .pcm71:
                // Enhanced stereo to 7.1 upmixing with advanced spatial processing
                return "extrastereo=m=3.0,haas,crystalizer=i=0.6,dynaudnorm=f=200,surround,aformat=channel_layouts=7.1"
            default:
                // Fallback to stereo
                return "aformat=channel_layouts=stereo"
            }
            
        case .truehd:
            // TrueHD with channel layout-specific processing
            switch channelLayout {
            case .spatial71:
                // TrueHD 7.1 Spatial Enhanced
                return "extrastereo=m=3.0,haas,crystalizer=i=0.8,dynaudnorm=f=250,surround,aformat=channel_layouts=7.1"
            case .atmosReady714:
                // TrueHD 7.1.4 Atmos Ready with height channels
                if useAI {
                    return createAISeparatedFilter(format: .truehd, channelLayout: .atmosReady714)
                } else {
                    return "extrastereo=m=3.2,haas,crystalizer=i=0.8,dynaudnorm=f=250,surround,pan=7.1.4|FL=FL|FR=FR|FC=FC|LFE=LFE|SL=SL|SR=SR|BL=BL|BR=BR|TFL=0.7*FL+0.3*FC|TFR=0.7*FR+0.3*FC|TBL=0.5*SL+0.3*BL|TBR=0.5*SR+0.3*BR"
                }
            case .enhanced71, .xReady714, .thx71, .thx714, .pcm20, .pcm51, .pcm71:
                // Fallback for other format layouts (shouldn't occur with TrueHD)
                return "extrastereo=m=3.0,haas,crystalizer=i=0.8,dynaudnorm=f=250,surround,aformat=channel_layouts=7.1"
            }
            
        case .dts:
            // DTS with channel layout-specific processing
            switch channelLayout {
            case .enhanced71:
                // DTS 7.1 Enhanced
                return "extrastereo=m=2.8,haas,crystalizer=i=0.5,dynaudnorm=f=175,surround,aformat=channel_layouts=7.1"
            case .xReady714:
                // DTS 7.1.4 :X Ready with height channels
                if useAI {
                    return createAISeparatedFilter(format: .dts, channelLayout: .xReady714)
                } else {
                    return "extrastereo=m=3.0,haas,crystalizer=i=0.6,dynaudnorm=f=200,surround,pan=7.1.4|FL=FL|FR=FR|FC=FC|LFE=LFE|SL=SL|SR=SR|BL=BL|BR=BR|TFL=0.6*FL+0.4*FC|TFR=0.6*FR+0.4*FC|TBL=0.4*SL+0.4*BL|TBR=0.4*SR+0.4*BR"
                }
            case .spatial71, .atmosReady714, .thx71, .thx714, .pcm20, .pcm51, .pcm71:
                // Fallback for other format layouts (shouldn't occur with DTS)
                return "extrastereo=m=2.8,haas,crystalizer=i=0.5,dynaudnorm=f=175,surround,aformat=channel_layouts=7.1"
            }
            
        case .thx:
            // THX LPCM with channel layout-specific processing
            switch channelLayout {
            case .thx71:
                // THX 7.1 Certified with precision processing
                return "extrastereo=m=2.0,haas,dynaudnorm=f=300,surround,aformat=channel_layouts=7.1,aformat=sample_fmts=s32"
            case .thx714:
                // THX 7.1.4 Spatial Audio with height channels
                if useAI {
                    return createAISeparatedFilter(format: .thx, channelLayout: .thx714)
                } else {
                    return "extrastereo=m=2.2,haas,dynaudnorm=f=300,surround,pan=7.1.4|FL=FL|FR=FR|FC=FC|LFE=LFE|SL=SL|SR=SR|BL=BL|BR=BR|TFL=0.8*FL+0.2*FC|TFR=0.8*FR+0.2*FC|TBL=0.6*SL+0.2*BL|TBR=0.6*SR+0.2*BR,aformat=sample_fmts=s32"
                }
            default:
                // Fallback for other layouts
                return "extrastereo=m=2.0,haas,dynaudnorm=f=300,surround,aformat=channel_layouts=7.1,aformat=sample_fmts=s32"
            }
        }
    }
    
    private func createAISeparatedFilter(format: AudioFormat, channelLayout: ChannelLayout) -> String {
        // This will be called AFTER Demucs separation
        // We'll create a complex filter graph using the separated stems
        
        switch channelLayout {
        case .atmosReady714:
            // Intelligent 7.1.4 mapping from Demucs stems
            return createIntelligent714Filter(format: format, enhanced: true)
        case .xReady714:
            // Intelligent 7.1.4 mapping for DTS:X
            return createIntelligent714Filter(format: format, enhanced: false)
        case .thx714:
            // Intelligent 7.1.4 mapping for THX Spatial Audio
            return createIntelligent714Filter(format: format, enhanced: true)
        default:
            // Fallback to standard processing
            return "extrastereo=m=3.0,haas,crystalizer=i=0.8,dynaudnorm=f=250,surround,aformat=channel_layouts=7.1"
        }
    }
    
    private func createIntelligent714Filter(format: AudioFormat, enhanced: Bool) -> String {
        // Create intelligent 7.1.4 mapping using separated stems
        // This filter assumes we have 4 input files: vocals, drums, bass, other
        let vocalsGain = enhanced ? "1.2" : "1.0"
        let drumsGain = enhanced ? "0.9" : "0.8"
        let bassGain = enhanced ? "1.5" : "1.3"
        let otherGain = enhanced ? "1.0" : "0.9"
        
        return """
        -filter_complex "
        [0:a]volume=\(vocalsGain)[vocals];
        [1:a]volume=\(drumsGain)[drums];
        [2:a]volume=\(bassGain)[bass];
        [3:a]volume=\(otherGain)[other];
        
        [vocals][drums]amix=inputs=2:weights=0.8 0.6[center_mix];
        [other]asplit=2[other_l][other_r];
        [other_l]volume=0.8[fl];
        [other_r]volume=0.8[fr];
        [bass]volume=1.0[lfe];
        [vocals]aecho=0.4:0.6:25:0.3[vocals_reverb];
        [other]volume=0.6[other_surround];
        [vocals_reverb][other_surround]amix=inputs=2[surround_base];
        [surround_base]asplit=4[sl][sr][bl][br];
        
        [vocals]highpass=f=5000,aecho=0.2:0.4:15:0.2,volume=0.5[height_base];
        [other]highpass=f=4000,volume=0.4[height_other];
        [height_base][height_other]amix=inputs=2[height_mix];
        [height_mix]asplit=4[tfl][tfr][tbl][tbr];
        
        [fl][fr][center_mix][lfe][sl][sr][bl][br][tfl][tfr][tbl][tbr]amerge=inputs=12,aformat=channel_layouts=7.1.4
        "
        """
    }
    
    private func runDemucsseparation(inputFile: URL, outputDir: URL) async throws -> URL {
        // Use bundled Python and Demucs wrapper
        guard let bundlePath = Bundle.main.resourcePath else {
            throw UpmixError.processFailed("Could not find app bundle resources")
        }
        
        let bundleURL = URL(fileURLWithPath: bundlePath)
        let pythonPath = bundleURL.appendingPathComponent("python")
        let wrapperScript = pythonPath.appendingPathComponent("demucs_wrapper.py")
        
        // Debug: Print paths to help troubleshoot
        print("Bundle path: \(bundlePath)")
        print("Python path: \(pythonPath.path)")
        print("Wrapper script path: \(wrapperScript.path)")
        print("Wrapper exists: \(FileManager.default.fileExists(atPath: wrapperScript.path))")
        
        // Check what's actually in the bundle Resources
        if let resourcesContents = try? FileManager.default.contentsOfDirectory(atPath: bundlePath) {
            print("Bundle Resources contents: \(resourcesContents)")
        }
        
        // Check if python folder exists and what's in it
        if FileManager.default.fileExists(atPath: pythonPath.path) {
            if let pythonContents = try? FileManager.default.contentsOfDirectory(atPath: pythonPath.path) {
                print("Python folder contents: \(pythonContents)")
            }
        } else {
            print("Python folder does not exist at: \(pythonPath.path)")
        }
        
        // Verify bundled components exist
        var finalWrapperScript = wrapperScript
        
        // Try different Python interpreters in order of preference
        let pythonInterpreters = [
            "/usr/bin/python3",
            "/opt/homebrew/bin/python3",
            "/usr/local/bin/python3",
            "/usr/bin/python"
        ]
        
        var selectedPython = "/usr/bin/python3"
        for interpreter in pythonInterpreters {
            if FileManager.default.fileExists(atPath: interpreter) {
                selectedPython = interpreter
                break
            }
        }
        
        if !FileManager.default.fileExists(atPath: wrapperScript.path) {
            // Try fallback to source directory during development
            let sourceWrapperPath = "/Users/cory/Documents/BDAA Upmixing Suite/BDAA Upmixing Suite/Resources/python/demucs_wrapper.py"
            if FileManager.default.fileExists(atPath: sourceWrapperPath) {
                finalWrapperScript = URL(fileURLWithPath: sourceWrapperPath)
                print("Using fallback wrapper path: \(sourceWrapperPath)")
            } else {
                throw UpmixError.processFailed("AI separation requires Python libraries that are not properly installed.")
            }
        }
        
        // Set environment to use bundled packages
        var environment = ProcessInfo.processInfo.environment
        let pythonLibPath = finalWrapperScript.deletingLastPathComponent().path
        
        // Set Python environment variables
        environment["PYTHONPATH"] = pythonLibPath
        environment["PYTHONUNBUFFERED"] = "1"
        environment["PYTHONDONTWRITEBYTECODE"] = "1"
        
        // Help resolve symbolic link issues
        environment["DYLD_LIBRARY_PATH"] = ""
        environment["DYLD_FRAMEWORK_PATH"] = ""
        
        // Set torch/model cache directories
        environment["TORCH_HOME"] = finalWrapperScript.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("models").path
        
        let tempDir = outputDir.appendingPathComponent("demucs_temp_\(UUID())")
        
        // Create temporary directory
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        let process = Process()
        print("Using Python interpreter: \(selectedPython)")
        
        process.executableURL = URL(fileURLWithPath: selectedPython)
        process.arguments = [
            "-u",  // Unbuffered output
            finalWrapperScript.path,
            inputFile.path,
            tempDir.path
        ]
        
        process.environment = environment
        
        print("Setting PYTHONPATH to: \(pythonLibPath)")
        print("Setting TORCH_HOME to: \(environment["TORCH_HOME"] ?? "not set")")
        print("Running wrapper at: \(finalWrapperScript.path)")
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        // Update status for AI processing
        await MainActor.run {
            self.status = "AI source separation in progress..."
        }
        
        try process.run()
        process.waitUntilExit()
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let outputText = String(data: outputData, encoding: .utf8) ?? ""
        let errorText = String(data: errorData, encoding: .utf8) ?? ""
        
        print("Demucs output: \(outputText)")
        if !errorText.isEmpty {
            print("Demucs errors: \(errorText)")
        }
        
        if process.terminationStatus != 0 {
            let combinedError = "Exit code: \(process.terminationStatus)\nOutput: \(outputText)\nError: \(errorText)"
            throw UpmixError.processFailed("Demucs separation failed: \(combinedError)")
        }
        
        // The wrapper script outputs stems directly to tempDir, so return that
        return tempDir
    }
    
    private func handleCancellation(from index: Int) async {
        for i in index..<files.count {
            await updateFileStatus(at: i, to: .cancelled)
        }
        status = "Upmix operation cancelled."
        progress = 1.0 // Show completion of cancellation
    }

    private func updateFileStatus(at index: Int, to newStatus: FileStatus, message: String? = nil) async {
        guard index < files.count else { return }
        files[index].status = newStatus
        if let message = message {
            status = message
        }
    }

    private func handleError(_ error: Error) {
        if let upmixError = error as? UpmixError {
            self.errorMessage = upmixError.localizedDescription
        } else {
            self.errorMessage = error.localizedDescription
        }
        self.status = "An error occurred."
    }
    
    private func resetStatus() {
        progress = 0.0
        status = "Ready"
        errorMessage = nil
    }
}

// MARK: - ContentView

struct ContentView: View {
    @StateObject private var upmixer = AudioUpmixer()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with logo and title - centered
            VStack(spacing: 20) {
                // Logo and title row
                HStack(alignment: .center, spacing: 40) {
                    Spacer()
                    
                    // App Logo
                    Image("AppLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .cornerRadius(22)
                    
                    // Title and subtitle - centered
                    VStack(alignment: .center, spacing: 8) {
                        Text("Professional Audio Upmixer")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(.appText)
                            .multilineTextAlignment(.center)
                        Text("Convert stereo audio to surround sound formats")
                            .font(.system(size: 16))
                            .foregroundColor(.appTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                }
                
                // Controls row - centered below title
                HStack(spacing: 30) {
                    Spacer()
                    
                    // Output Format
                    VStack(alignment: .leading, spacing: 4) {
                        // Info text for PCM 2.0
                        if upmixer.selectedFormat == .pcm && upmixer.selectedChannelLayout == .pcm20 {
                            Text("All channels will be downmixed to stereo")
                                .font(.system(size: 11))
                                .foregroundColor(.appTextSecondary)
                                .italic()
                        }
                        
                        HStack(spacing: 8) {
                            Text("Output Format:")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.appText)
                            
                            Picker("", selection: $upmixer.selectedFormat) {
                                ForEach(AudioFormat.allCases, id: \.self) { format in
                                    Text(format.displayName).tag(format)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .disabled(upmixer.isUpmixing)
                            .frame(width: 150)
                        }
                    }
                    
                    // Quality - Only for PCM format
                    if upmixer.selectedFormat == .pcm {
                        HStack(spacing: 8) {
                            Text("Quality:")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.appText)
                            
                            Picker("", selection: $upmixer.selectedQuality) {
                                ForEach(AudioQuality.allCases, id: \.self) { quality in
                                    Text(quality.displayName).tag(quality)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .disabled(upmixer.isUpmixing)
                            .frame(width: 140)
                        }
                    }
                    
                    // THX Quality Notice - Always 24-bit/96kHz
                    if upmixer.selectedFormat == .thx {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("THX Quality: 24-bit / 96 kHz")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.appAccent)
                            Text("(Fixed THX Certified standard)")
                                .font(.system(size: 11))
                                .foregroundColor(.appTextSecondary)
                                .italic()
                        }
                    }
                    
                    // Channels - For PCM, TrueHD, DTS, and THX formats
                    if [AudioFormat.pcm, .truehd, .dts, .thx].contains(upmixer.selectedFormat) {
                        HStack(spacing: 8) {
                            Text("Channels:")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.appText)
                            
                            Picker("", selection: $upmixer.selectedChannelLayout) {
                                ForEach(ChannelLayout.options(for: upmixer.selectedFormat), id: \.self) { layout in
                                    Text(layout.displayName).tag(layout)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .disabled(upmixer.isUpmixing)
                            .frame(width: 160)
                            .onChange(of: upmixer.selectedFormat) { newFormat in
                                // Reset to appropriate default when format changes
                                if newFormat == .pcm && !ChannelLayout.options(for: newFormat).contains(upmixer.selectedChannelLayout) {
                                    upmixer.selectedChannelLayout = .pcm51
                                } else if newFormat == .truehd && !ChannelLayout.options(for: newFormat).contains(upmixer.selectedChannelLayout) {
                                    upmixer.selectedChannelLayout = .spatial71
                                } else if newFormat == .dts && !ChannelLayout.options(for: newFormat).contains(upmixer.selectedChannelLayout) {
                                    upmixer.selectedChannelLayout = .enhanced71
                                } else if newFormat == .thx && !ChannelLayout.options(for: newFormat).contains(upmixer.selectedChannelLayout) {
                                    upmixer.selectedChannelLayout = .thx71
                                }
                            }
                        }
                    }
                    
                    // AI Source Separation - Only for 7.1.4 formats (Atmos Ready, :X Ready, and THX Spatial)
                    if [ChannelLayout.atmosReady714, .xReady714, .thx714].contains(upmixer.selectedChannelLayout) {
                        HStack(spacing: 8) {
                            Toggle("AI Source Separation", isOn: $upmixer.useAISeparation)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.appText)
                                .disabled(upmixer.isUpmixing)
                            
                            Text("(Slower, Higher Quality)")
                                .font(.system(size: 12))
                                .foregroundColor(.appTextSecondary)
                        }
                        .onChange(of: upmixer.selectedChannelLayout) { newLayout in
                            // Auto-disable AI separation when switching away from 7.1.4 formats
                            if ![ChannelLayout.atmosReady714, .xReady714, .thx714].contains(newLayout) {
                                upmixer.useAISeparation = false
                            }
                        }
                    }
                    
                    // File Format
                    HStack(spacing: 8) {
                        Text("Format:")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.appText)
                        
                        Picker("", selection: $upmixer.selectedFileFormat) {
                            ForEach(FileFormat.allCases.filter { $0.isCompatible(with: upmixer.selectedFormat) }, id: \.self) { format in
                                Text(format.rawValue)
                                    .tag(format)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .disabled(upmixer.isUpmixing)
                        .frame(width: 100)
                        .onChange(of: upmixer.selectedFormat) { _ in
                            // Auto-select compatible format when audio format changes
                            if !upmixer.selectedFileFormat.isCompatible(with: upmixer.selectedFormat) {
                                if let compatibleFormat = FileFormat.allCases.first(where: { $0.isCompatible(with: upmixer.selectedFormat) }) {
                                    upmixer.selectedFileFormat = compatibleFormat
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 30)
            
            // Main Drop Area
            VStack {
                if upmixer.files.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        
                        Text("Drag audio files here or click Select Files")
                            .font(.system(size: 16))
                            .foregroundColor(.appTextSecondary)
                        
                        Spacer()
                    }
                } else {
                    // File list
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(upmixer.files) { file in
                                FileRowView(file: file)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.appBorder, style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
            )
            .padding(.horizontal, 20)
            .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                return handleFileDrop(providers: providers)
            }
            
            Spacer()
            
            // Output Directory Section
            HStack {
                Text("Output To:")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.appText)
                
                // Text field that accepts drops
                TextField("Drag folder here or click to browse", text: .constant(upmixer.outputDirectory?.originalURL.path ?? ""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(true)
                    .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                        return handleDirectoryDrop(providers: providers)
                    }
                
                Button(action: {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.allowsMultipleSelection = false
                    
                    let response = panel.runModal()
                    if response == .OK, let url = panel.urls.first {
                        upmixer.setOutputDirectory(url: url)
                    }
                }) {
                    Image(systemName: "folder")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(upmixer.isUpmixing)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.appSecondary)
            
            // Status and Progress
            VStack(spacing: 8) {
                HStack {
                    if upmixer.isUpmixing {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text(upmixer.status)
                            .font(.system(size: 14))
                            .foregroundColor(.appText)
                    } else {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 8, height: 8)
                        Text(upmixer.status)
                            .font(.system(size: 14))
                            .foregroundColor(.appTextSecondary)
                    }
                    Spacer()
                }
                
                if upmixer.isUpmixing {
                    ProgressView(value: upmixer.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .appAccent))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // Bottom Controls
            HStack(spacing: 16) {
                FilePickerButton(
                    title: "Select Files",
                    isForFiles: true,
                    allowsMultiple: true
                ) { urls in
                    for url in urls {
                        upmixer.addFile(url: url)
                    }
                }
                .disabled(upmixer.isUpmixing)
                
                Spacer()
                
                if !upmixer.files.isEmpty {
                    Button(action: {
                        upmixer.clearFiles()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                                .font(.system(size: 16))
                            Text("Clear")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.appTextSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.appSecondary)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(upmixer.isUpmixing)
                }
                
                if upmixer.isUpmixing {
                    Button(action: {
                        upmixer.cancelUpmixing()
                    }) {
                        Text("Cancel")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Button(action: {
                        upmixer.startUpmixing()
                    }) {
                        Text("Convert to \([AudioFormat.pcm, .truehd, .dts, .thx].contains(upmixer.selectedFormat) ? "\(upmixer.selectedFormat.displayName) \(upmixer.selectedChannelLayout.channelCount)" : upmixer.selectedFormat.displayName)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(upmixer.files.isEmpty || upmixer.outputDirectory == nil ? Color.appBorder : Color.appAccent)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(upmixer.files.isEmpty || upmixer.outputDirectory == nil)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            
            // Error Display
            if let errorMessage = upmixer.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)
            }
        }
        .background(Color.appBackground)
    }
    
    // MARK: - Drag and Drop Handlers
    
    private func handleFileDrop(providers: [NSItemProvider]) -> Bool {
        guard !upmixer.isUpmixing else { return false }
        
        for provider in providers {
            if provider.canLoadObject(ofClass: URL.self) {
                _ = provider.loadObject(ofClass: URL.self) { url, error in
                    if let url = url {
                        DispatchQueue.main.async {
                            // Check if it's an audio file
                            let audioExtensions = ["mp3", "wav", "flac", "m4a", "aac", "aiff", "caf"]
                            if audioExtensions.contains(url.pathExtension.lowercased()) {
                                upmixer.addFile(url: url)
                            }
                        }
                    }
                }
            }
        }
        return true
    }
    
    private func handleDirectoryDrop(providers: [NSItemProvider]) -> Bool {
        guard !upmixer.isUpmixing else { return false }
        
        for provider in providers {
            if provider.canLoadObject(ofClass: URL.self) {
                _ = provider.loadObject(ofClass: URL.self) { url, error in
                    if let url = url {
                        DispatchQueue.main.async {
                            // Check if it's a directory
                            var isDirectory: ObjCBool = false
                            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue {
                                upmixer.setOutputDirectory(url: url)
                            }
                        }
                    }
                }
            }
        }
        return true
    }
}

struct FileRowView: View {
    let file: AudioFile
    
    var body: some View {
        HStack {
            Image(systemName: "music.note")
                .font(.system(size: 16))
                .foregroundColor(.appTextSecondary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(file.bookmarkedURL.originalURL.lastPathComponent)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.appText)
                    .lineLimit(1)
                
                Text(file.status.rawValue)
                    .font(.system(size: 12))
                    .foregroundColor(file.status.color)
            }
            
            Spacer()
            
            statusIcon(for: file.status)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.appSecondary.opacity(0.7))
        .cornerRadius(8)
    }
    
    private func statusIcon(for status: FileStatus) -> some View {
        Group {
            switch status {
            case .pending:
                Image(systemName: "clock")
                    .foregroundColor(.appTextSecondary)
            case .processing:
                ProgressView()
                    .scaleEffect(0.7)
                    .progressViewStyle(CircularProgressViewStyle(tint: .appAccent))
            case .upmixed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .failed:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            case .cancelled:
                Image(systemName: "stop.circle.fill")
                    .foregroundColor(.orange)
            }
        }
        .font(.system(size: 16))
    }
}

// Simple button-based file picker for macOS 11.5 compatibility
struct FilePickerButton: View {
    let title: String
    let isForFiles: Bool
    let allowsMultiple: Bool
    let onComplete: ([URL]) -> Void
    
    var body: some View {
        Button(action: {
            let panel = NSOpenPanel()
            panel.canChooseFiles = isForFiles
            panel.canChooseDirectories = !isForFiles
            panel.allowsMultipleSelection = allowsMultiple
            
            if isForFiles {
                if #available(macOS 12.0, *) {
                    panel.allowedContentTypes = [.audio]
                } else {
                    panel.allowedFileTypes = ["mp3", "wav", "flac", "m4a", "aac", "aiff", "caf", "m4v", "mp4", "mov"]
                }
            }
            
            let response = panel.runModal()
            if response == .OK {
                onComplete(panel.urls)
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 16))
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.appText)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.appSecondary)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
