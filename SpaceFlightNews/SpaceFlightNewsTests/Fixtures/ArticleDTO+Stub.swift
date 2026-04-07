// Fixtures/ArticleDTO+Stub.swift
// Test fixtures for ArticleDTO data transfer object.

import Foundation
@testable import SpaceFlightNews

extension ArticleDTO {
    static func stub(
        id: Int = 1,
        title: String = "SpaceX Falcon 9 Launch",
        url: String = "https://example.com/article",
        imageUrl: String? = "https://example.com/image.jpg",
        newsSite: String = "SpaceNews",
        summary: String = "A rocket was launched successfully.",
        publishedAt: String = "2024-01-15T10:30:00Z",
        updatedAt: String = "2024-01-15T10:30:00Z"
    ) -> ArticleDTO {
        ArticleDTO(
            id: id,
            title: title,
            url: url,
            imageUrl: imageUrl,
            newsSite: newsSite,
            summary: summary,
            publishedAt: publishedAt,
            updatedAt: updatedAt
        )
    }
}
