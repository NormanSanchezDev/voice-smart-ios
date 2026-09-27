// This package is iOS-only, and the compiler says so once instead of saying it
// five hundred times.
//
// `AudioEngineRecorder` drives `AVAudioSession` and `AVAudioEngine.inputNode`,
// `OnDeviceTranscriber` drives the on-device Speech frameworks, and
// `OnDeviceNoteEnricher` drives FoundationModels. None of those exist on macOS,
// and none of them are deprecated-by-a-replacement either — they simply have no
// macOS spelling. Without this guard, an `xcodebuild … -destination
// 'generic/platform=macOS'` or a stray `swift build` on the Mac type-checks the
// whole module against the default macOS floor and emits an availability warning
// per API reference, which reads like a hundred unrelated problems instead of the
// one thing that is actually wrong.
//
// `NoteSmartDomain` and `NoteSmartDesignSystem` are portable and deliberately
// carry no such guard: the domain is plain Foundation and the design system is
// SwiftUI, so both build anywhere.
#if !os(iOS)
#error("NoteSmartData is iOS-only: AVAudioSession, on-device Speech and FoundationModels have no macOS API. Build this package with an iOS destination.")
#endif
