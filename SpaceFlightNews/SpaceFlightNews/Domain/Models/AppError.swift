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
        case .networkUnavailable: return String(localized: "error.network.description")
        case .serverError:        return String(localized: "error.server.description")
        case .dataCorrupted:      return String(localized: "error.dataCorrupted.description")
        case .unknown:            return String(localized: "error.unknown.description")
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable: return String(localized: "error.network.recovery")
        default:                  return String(localized: "error.generic.recovery")
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
