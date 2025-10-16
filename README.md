<div align="center">

# BDAA Upmixing Suite

A professional macOS application for converting stereo audio to enhanced surround sound formats with advanced spatial processing and synthetic height channel simulation.

![BDAA Upmixing Suite Screenshot](screenshot.png)

</div>

## Features

### 🎵 Enhanced Audio Processing
- **PCM 2.0** - Stereo audio (no upmixing)
- **PCM 5.1** - Enhanced 5.1 surround with spatial processing
- **PCM 7.1** - Advanced 7.1 surround with enhanced imaging
- **Atmos Ready 7.1.4** - 7.1.4 compatible with synthetic height channels
- **TrueHD 7.1 Spatial Enhanced** - Enhanced TrueHD with advanced spatial processing
- **TrueHD 7.1.4 Enhanced** - TrueHD with true 7.1.4 height channels
- **DTS 7.1 Enhanced** - DTS with advanced surround imaging
- **DTS 7.1.4 :X Ready** - DTS with 7.1.4 height channel simulation
- **THX 7.1 Certified** - THX-optimized 7.1 surround processing
- **THX 7.1.4 Spatial Audio** - THX-certified spatial audio with height channels

### 🔧 Flexible Quality Options
- **16-bit / 48 kHz** - Standard quality
- **24-bit / 48 kHz** - Professional quality
- **24-bit / 96 kHz** - High resolution
- **24-bit / 192 kHz** - Audiophile quality
- **32-bit / 48 kHz** - Maximum bit depth
- **32-bit / 96 kHz** - High resolution with maximum bit depth
- **32-bit / 192 kHz** - Ultimate quality

### 📁 Multiple File Format Support
- **FLAC** - Free Lossless Audio Codec
- **ALAC** - Apple Lossless Audio Codec
- **WAV** - Uncompressed audio
- **AIFF** - Audio Interchange File Format
- **DTS** - For DTS 7.1 Enhanced output
- **TrueHD** - For TrueHD 7.1 Spatial output

### 🖱️ Intuitive User Interface
- **Drag & Drop** - Drop audio files directly into the main area
- **Smart Format Restrictions** - File formats automatically filter based on output type
- **Folder Drop Support** - Drag folders directly into the output directory field
- **Professional Dark Blue Theme** - Easy on the eyes for long sessions
- **Real-time Progress Tracking** - Monitor conversion status for each file

## System Requirements

- macOS 11.5 or later
- FFmpeg (bundled with application - no manual installation required)
- Sufficient disk space for output files

## Installation

1. Clone this repository
2. Open `BDAA Upmixing Suite.xcodeproj` in Xcode
3. Build and run the project
4. FFmpeg is bundled automatically - no manual installation needed

### macOS Security Notice

If you encounter a "cannot scan for malware" warning when running the built app:

**Option 1: Developer Signing (Recommended)**
- Join the Apple Developer Program
- Code sign the application with your Developer ID certificate
- Optionally notarize for complete trust

**Option 2: User Override**
- Right-click the app → "Open" → "Open" to bypass the warning
- Or go to System Preferences → Security & Privacy → "Open Anyway"

This warning appears because the app is not code-signed by an Apple Developer ID certificate.

## Usage

1. **Select Output Format** - Choose your desired surround sound format
2. **Choose Quality** - Select bit depth and sample rate (for PCM formats)
3. **Pick File Format** - Choose output container format
4. **Add Audio Files** - Drag audio files into the drop area or click "Select Files"
5. **Set Output Directory** - Drag a folder into the output field or click the folder icon
6. **Convert** - Click the convert button to start processing

## Smart Format Logic

The application intelligently restricts file format options based on your output format selection:

- **PCM Formats** (2.0, 5.1, 7.1) + **Atmos Ready 7.1.4**: FLAC, ALAC, WAV, AIFF available
- **TrueHD Formats** (7.1 Spatial Enhanced, 7.1.4 Enhanced): Only TrueHD (.thd) available
- **DTS Enhanced Formats** (7.1 Enhanced, 7.1.4 :X Ready): Only DTS (.dts) available
- **THX Formats** (7.1 Certified, 7.1.4 Spatial Audio): FLAC, ALAC, WAV, AIFF available

## Technical Details

### Enhanced Audio Processing
- Uses bundled FFmpeg 7.1 for high-quality audio processing
- Advanced spatial processing with stereo field enhancement
- Psychoacoustic depth enhancement using Haas effect
- Dynamic range optimization and clarity enhancement
- Supports security-scoped bookmarks for sandboxed file access

### Spatial Processing Algorithms
- **Enhanced Stereo Field**: Widens stereo image before upmixing using `extrastereo`
- **Haas Effect**: Adds psychoacoustic depth perception with subtle delays
- **Dynamic Normalization**: Optimizes dynamic range while preserving transients
- **Clarity Enhancement**: Uses `crystalizer` for enhanced detail and presence
- **Synthetic Height Channels**: Creates 7.1.4 compatible output with height simulation
- **Spatial TrueHD/DTS**: Enhanced encoding with advanced spatial imaging
- **THX Certification**: Optimized processing for THX-certified playback systems

## File Format Specifications

| Format | Container | Codec | Best For |
|--------|-----------|-------|----------|
| FLAC | .flac | flac | Open source lossless, PCM/THX formats |
| ALAC | .m4a | alac | Apple ecosystem, PCM/THX formats |
| WAV | .wav | pcm_s32le | Universal compatibility, PCM/THX formats |
| AIFF | .aiff | pcm_s32be | Pro audio workflows, PCM/THX formats |
| DTS | .dts | dca | Enhanced spatial DTS, DTS :X Ready |
| TrueHD | .thd | truehd | Spatial surround content, Atmos Ready |

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project uses a proprietary license with source code access. See the LICENSE file for complete terms.

**Quick Summary:**
- ✅ Source code access: Granted
- ✅ Modification for personal/internal use: Allowed  
- ❌ Redistribution: Prohibited without permission
- ❌ Commercial resale: Prohibited without a paid license

For commercial licensing inquiries: Retrowrangler@homemail.com

## Acknowledgments

- Built with SwiftUI for modern macOS development
- Powered by bundled FFmpeg 7.1 for advanced audio processing
- Enhanced with spatial processing algorithms for professional results
- Designed for professional audio production workflows
- Supports industry-standard formats for maximum compatibility

---

**Note**: This application converts stereo audio to enhanced surround sound using advanced spatial processing algorithms. While not true discrete multichannel audio, the enhanced processing provides significantly improved spatial imaging and immersive audio experiences. FFmpeg is bundled with the application for seamless operation.