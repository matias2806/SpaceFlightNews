// Data/Mappers/ArticleMapper.swift
// Pure functions: ArticleDTO → Article (domain model).
// Caseless enum = no instances, no state — acts as a namespace.
//
// ⚠️ ISO8601DateFormatter is expensive to instantiate (parses the format string
// on init). Declared as a static let so it's created once and reused across
// every article in the list — critical when mapping 20+ items per page.

import Foundation

enum ArticleMapper {

    // MARK: - Date formatter (created once, reused always)

    private static let dateFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        // Handles both "2021-01-01T00:00:00Z" and "2021-01-01T00:00:00.000Z"
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    // Fallback formatter without fractional seconds for strict ISO8601
    private static let dateFormatterStrict: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    // MARK: - Mapping

    /// Maps a single DTO to its domain model.
    /// Throws `AppError.mappingFailed` if the article URL is invalid.
    static func toDomain(_ dto: ArticleDTO) throws -> Article {
        guard let articleURL = URL(string: dto.url) else {
            throw AppError.mappingFailed("Invalid article URL: \(dto.url)")
        }

        return Article(
            id: dto.id,
            title: dto.title,
            articleURL: articleURL,
            imageURL: dto.imageUrl.flatMap(URL.init),
            newsSite: dto.newsSite,
            summary: dto.summary,
            publishedAt: parseDate(dto.publishedAt)
        )
    }

    /// Maps a list of DTOs, skipping articles with invalid URLs and logging each skip.
    static func toDomain(_ dtos: [ArticleDTO]) -> [Article] {
        dtos.compactMap { dto in
            do {
                return try toDomain(dto)
            } catch {
                AppLogger.networkError(
                    AppError.mappingFailed("Skipping article id=\(dto.id): \(error)")
                )
                return nil
            }
        }
    }

    // MARK: - Private helpers

    private static func parseDate(_ string: String) -> Date {
        // Try with fractional seconds first (most common in this API),
        // then fall back to strict format.
        dateFormatter.date(from: string)
            ?? dateFormatterStrict.date(from: string)
            ?? .distantPast
    }
}
