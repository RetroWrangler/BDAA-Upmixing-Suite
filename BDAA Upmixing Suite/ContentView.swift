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
    case pcm20 = "PCM 2.0"
    case pcm51 = "PCM 5.1"
    case pcm71 = "PCM 7.1"
    case dolbyAtmos = "Dolby Atmos"
    case dtsMasterAudio = "DTS Master Audio"
    
    
    var channelLayout: String {
        switch self {
        case .pcm20:
            return "stereo"
        case .pcm51:
            return "5.1"
        case .pcm71:
            return "7.1"
        case .dolbyAtmos:
            return "7.1.4"  // 7.1 + 4 height channels
        case .dtsMasterAudio:
            return "7.1"
        }
    }
    
    var displayName: String {
        return self.rawValue
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
    case dts = "DTS"
    case truehd = "TrueHD"
    
    var fileExtension: String {
        switch self {
        case .flac: return "flac"
        case .alac: return "m4a"
        case .wav: return "wav"
        case .aiff: return "aiff"
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
        case .dts: return "dca"
        case .truehd: return "truehd"
        }
    }
    
    func isCompatible(with audioFormat: AudioFormat) -> Bool {
        switch audioFormat {
        case .pcm20, .pcm51, .pcm71:
            return [.flac, .alac, .wav, .aiff].contains(self)
        case .dolbyAtmos:
            return self == .truehd
        case .dtsMasterAudio:
            return self == .dts
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
        // This will be a security-scoped URL
        var isStale = false
        guard let resolvedURL = try? URL(resolvingBookmarkData: bookmarkedURL.bookmarkData,
                                         options: .withSecurityScope,
                                         relativeTo: nil,
                                         bookmarkDataIsStale: &isStale) else {
            // Fallback to original URL, though access may fail
            return bookmarkedURL.originalURL
        }
        
        if isStale {
            // Handle stale bookmark data if necessary
            print("Warning: Bookmark data is stale for \(bookmarkedURL.originalURL.lastPathComponent)")
        }
        
        return resolvedURL
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
    @Published var selectedFormat: AudioFormat = .pcm51
    @Published var selectedQuality: AudioQuality = .standard
    @Published var selectedFileFormat: FileFormat = .flac

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
        task.launchPath = "/usr/bin/which"
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
            handleError(UpmixError.bookmarkFailed)
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            self.outputDirectory = BookmarkedURL(bookmarkData: bookmarkData, originalURL: url)
        } catch {
            handleError(UpmixError.bookmarkFailed)
        }
    }
    
    func addFile(url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            handleError(UpmixError.bookmarkFailed)
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
            handleError(UpmixError.bookmarkFailed)
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
        guard let outputDirURL = try? URL(resolvingBookmarkData: outputDir.bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) else {
            throw UpmixError.bookmarkFailed
        }
        
        guard outputDirURL.startAccessingSecurityScopedResource() else {
            throw UpmixError.processFailed("Could not access output directory.")
        }
        defer { outputDirURL.stopAccessingSecurityScopedResource() }

        let outputFileName = file.bookmarkedURL.originalURL.deletingPathExtension().lastPathComponent + "_\(selectedFormat.channelLayout).\(selectedFileFormat.fileExtension)"
        let outputURL = outputDirURL.appendingPathComponent(outputFileName)
        
        let filter = createFFmpegFilter(for: selectedFormat)
        var arguments = ["-i", file.url.path, "-vn"]
        
        // Add format-specific arguments
        switch selectedFormat {
        case .pcm20, .pcm51, .pcm71:
            arguments += [
                "-af", filter,
                "-c:a", selectedFileFormat.ffmpegCodec,
                "-sample_fmt", selectedQuality.bitDepth,
                "-ar", selectedQuality.sampleRate
            ]
            
        case .dolbyAtmos:
            // Dolby Atmos TrueHD has fixed requirements
            arguments += [
                "-af", filter,
                "-c:a", selectedFileFormat.ffmpegCodec,
                "-ar", "48000",  // TrueHD standard is 48kHz
                "-strict", "experimental"
            ]
            
        case .dtsMasterAudio:
            // DTS Master Audio has fixed requirements
            arguments += [
                "-af", filter,
                "-c:a", selectedFileFormat.ffmpegCodec,
                "-b:a", "1536k",
                "-ar", "48000",  // DTS standard is 48kHz
                "-strict", "experimental"
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
    
    private func createFFmpegFilter(for format: AudioFormat) -> String {
        switch format {
        case .pcm20:
            // Simple stereo (no upmixing needed)
            return "aformat=channel_layouts=stereo"
            
        case .pcm51:
            // Stereo to 5.1 upmixing
            return "pan=5.1(side)|FL=FL|FR=FR|FC=0.5*FL+0.5*FR|LFE=0.1*FL+0.1*FR|SL=0.5*FL|SR=0.5*FR"
            
        case .pcm71:
            // Stereo to 7.1 upmixing
            return "pan=7.1|FL=FL|FR=FR|FC=0.5*FL+0.5*FR|LFE=0.1*FL+0.1*FR|SL=0.7*FL|SR=0.7*FR|BL=0.3*FL|BR=0.3*FR"
            
        case .dolbyAtmos:
            // Stereo to 7.1.4 for Dolby Atmos (includes height channels)
            return "pan=7.1.4|FL=FL|FR=FR|FC=0.5*FL+0.5*FR|LFE=0.1*FL+0.1*FR|SL=0.7*FL|SR=0.7*FR|BL=0.3*FL|BR=0.3*FR|TFL=0.2*FL|TFR=0.2*FR|TBL=0.1*FL|TBR=0.1*FR"
            
        case .dtsMasterAudio:
            // Stereo to 7.1 for DTS Master Audio
            return "pan=7.1|FL=FL|FR=FR|FC=0.5*FL+0.5*FR|LFE=0.1*FL+0.1*FR|SL=0.7*FL|SR=0.7*FR|BL=0.3*FL|BR=0.3*FR"
        }
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
                    
                    // Quality - Only for PCM formats
                    if [AudioFormat.pcm20, .pcm51, .pcm71].contains(upmixer.selectedFormat) {
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
                        Text("Convert to \(upmixer.selectedFormat.displayName)")
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
