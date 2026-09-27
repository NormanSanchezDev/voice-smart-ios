import Foundation

public enum NoteError: Error, Equatable, Sendable {
    case noteNotFound(NoteID)
    case noteNotFoundAtPath(String)
    case vaultUnavailable(reason: String)
    case malformedMarkdown(reason: String)
    case fileNameConflict(String)
    case indexCorrupted(reason: String)
    case permissionDenied
    case cancelled
}

public enum TranscriptionError: Error, Equatable, Sendable {
    case permissionDenied
    case unavailableOnDevice
    case unsupportedLocale(String)
    case modelInstallFailed(reason: String)
    case audioUnreadable(reason: String)
    case emptyRecording
}

public enum EnrichmentError: Error, Equatable, Sendable {
    case modelUnavailable(AIUnavailableReason)
    case guardrailViolation
    case contextWindowExceeded
    case unsupportedLanguage
    case cancelled
}
