// Data/Network/APIClient.swift
// Protocol + URLSession implementation.
// URLSession is injected by init — swap it for a MockURLSession in tests.

import Foundation

// MARK: - Protocol

protocol APIClientProtocol: Sendable {
    func fetch<T: Decodable & Sendable>(_ endpoint: APIEndpoint) async throws -> T
}

// MARK: - Implementation

final class URLSessionAPIClient: APIClientProtocol {

    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    func fetch<T: Decodable & Sendable>(_ endpoint: APIEndpoint) async throws -> T {
        let request: URLRequest
        do {
            request = try endpoint.urlRequest()
        } catch {
            throw error as? AppError ?? AppError.invalidEndpoint
        }

        AppLogger.networkInfo("→ \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            let appError = Self.mapURLError(urlError)
            AppLogger.networkError(appError)
            throw appError
        }

        guard let http = response as? HTTPURLResponse else {
            throw AppError.invalidResponse
        }

        AppLogger.networkInfo("← HTTP \(http.statusCode) (\(data.count) bytes)")

        guard (200..<300).contains(http.statusCode) else {
            let error = AppError.serverError(statusCode: http.statusCode)
            AppLogger.networkError(error)
            throw error
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            let appError = AppError.decodingFailed(error)
            AppLogger.networkError(appError)
            throw appError
        }
    }

    // MARK: - URLError mapping

    private static func mapURLError(_ error: URLError) -> AppError {
        switch error.code {
        case .notConnectedToInternet,
             .networkConnectionLost,
             .dataNotAllowed:
            return .networkUnavailable
        default:
            return .unknown(error)
        }
    }
}
