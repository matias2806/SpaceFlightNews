// Domain/Models/AppError.swift
// Four cases — enough to drive distinct UX without over-engineering.
// Rule: status codes and internal details go to AppLogger, never to the UI.

import Foundation

enum AppError: Error, LocalizedError, CustomDebugStringConvertible, Equatable {

    case networkUnavailable          // user has no internet
    case serverError(statusCode: Int) // HTTP 4xx/5xx — kept for logging; never shown raw
    case dataCorrupted               // decoding or mapping failed
    case unknown                     // anything else

    // MARK: - User-facing (no technical details)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Sin conexión a internet."
        case .serverError:
            return "Error del servidor. Intentá más tarde."
        case .dataCorrupted:
            return "No pudimos procesar la respuesta."
        case .unknown:
            return "Algo salió mal. Intentá de nuevo."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Verificá tu conexión y volvé a intentar."
        default:
            return "Tocá Reintentar para cargar nuevamente."
        }
    }

    // MARK: - Developer logging (full detail, never reaches UI)

    var debugDescription: String {
        switch self {
        case .networkUnavailable:        return "AppError.networkUnavailable"
        case .serverError(let code):     return "AppError.serverError(statusCode: \(code))"
        case .dataCorrupted:             return "AppError.dataCorrupted"
        case .unknown:                   return "AppError.unknown"
        }
    }
}
// Equatable is synthesized automatically — no manual == needed.
