//
//  AppErrorMessage.swift
//  NoteSmart
//

import Foundation
import NoteSmartDomain

/// Turns a domain error into something worth showing a person.
///
/// The domain errors are precise on purpose — they name the vault path, the note id,
/// the reason Speech refused. None of that belongs in a label. Keeping the mapping
/// here rather than in each view means the same failure always reads the same way,
/// and no feature has to pattern-match on three error enums to render a message.
enum AppErrorMessage {

    static func text(for error: Error) -> String {
        switch error {
        case let error as NoteError:
            return text(for: error)
        case let error as TranscriptionError:
            return text(for: error)
        case let error as EnrichmentError:
            return text(for: error)
        default:
            return "Algo salió mal. Inténtalo de nuevo."
        }
    }

    static func text(for error: NoteError) -> String {
        switch error {
        case .noteNotFound, .noteNotFoundAtPath:
            "La nota ya no está en el vault."
        case let .vaultUnavailable(reason):
            "No se pudo abrir el vault: \(reason)"
        case .malformedMarkdown:
            "El archivo markdown no se pudo leer."
        case .fileNameConflict:
            "Ya existe una nota con ese nombre."
        case .indexCorrupted:
            "El índice de búsqueda se reconstruirá."
        case .permissionDenied:
            "NoteSmart no tiene permiso para leer tus archivos."
        case .cancelled:
            "Operación cancelada."
        }
    }

    static func text(for error: TranscriptionError) -> String {
        switch error {
        case .permissionDenied:
            "NoteSmart no tiene permiso para usar el micrófono."
        case .unavailableOnDevice:
            "La transcripción en el dispositivo no está disponible en este idioma."
        case let .unsupportedLocale(locale):
            "No hay modelo de voz para \(locale)."
        case .modelInstallFailed:
            "No se pudo descargar el modelo de voz."
        case .audioUnreadable:
            "No se pudo leer el audio grabado."
        case .emptyRecording:
            "La grabación está vacía."
        }
    }

    static func text(for error: EnrichmentError) -> String {
        switch error {
        case .modelUnavailable:
            "Este dispositivo no puede mejorar la nota con IA. Se guardó sin tocar."
        case .guardrailViolation:
            "La IA no pudo procesar esta nota. Se guardó sin tocar."
        case .contextWindowExceeded:
            "La nota es demasiado larga para mejorarla con IA."
        case .unsupportedLanguage:
            "La IA no habla este idioma todavía. Se guardó sin tocar."
        case .cancelled:
            "Operación cancelada."
        }
    }
}
