// Domain/Models/AppError.swift
// Single error type that travels across all layers.
// - errorDescription: user-facing, safe to display in UI
// - debugDescription: full technical detail for AppLogger

import Foundation

enum AppError: Error, LocalizedError, CustomDebugStringConvertible {

    case networkUnavailable
    case serverError(statusCode: Int)
    case decodingFailed(Error)
    case mappingFailed(String)
    case invalidResponse
    case invalidEndpoint
    case unknown(Error)

    // MARK: - User-facing

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Sin conexión a internet."
        case .serverError(let code):
            return "Error del servidor (\(code)). Intentá más tarde."
        case .decodingFailed, .mappingFailed:
            return "No pudimos procesar la respuesta."
        case .invalidResponse, .invalidEndpoint, .unknown:
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

    // MARK: - Developer logging

    var debugDescription: String {
        switch self {
        case .networkUnavailable:         return "AppError.networkUnavailable"
        case .serverError(let code):      return "AppError.serverError(statusCode: \(code))"
        case .decodingFailed(let error):  return "AppError.decodingFailed: \(error)"
        case .mappingFailed(let reason):  return "AppError.mappingFailed: \(reason)"
        case .invalidResponse:            return "AppError.invalidResponse"
        case .invalidEndpoint:            return "AppError.invalidEndpoint"
        case .unknown(let error):         return "AppError.unknown: \(error)"
        }
    }
}

// MARK: - Equatable
// Manual conformance required — associated Error values don't conform to Equatable.

extension AppError: Equatable {
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case (.networkUnavailable, .networkUnavailable):  return true
        case (.invalidResponse, .invalidResponse):        return true
        case (.invalidEndpoint, .invalidEndpoint):        return true
        case (.serverError(let a), .serverError(let b)):  return a == b
        case (.mappingFailed(let a), .mappingFailed(let b)): return a == b
        // For error-wrapping cases we consider them equal by kind, not by value,
        // since Error instances aren't reliably comparable.
        case (.decodingFailed, .decodingFailed):          return true
        case (.unknown, .unknown):                        return true
        default:                                          return false
        }
    }
}
