// Fixtures/Article+Stub.swift
// Test fixtures for Article domain model.

import Foundation
@testable import SpaceFlightNews

extension Article {
    static func stub(
        id: Int = 1,
        title: String = "SpaceX Falcon 9 Launch",
        articleURL: URL = URL(string: "https://example.com/article")!,
        imageURL: URL? = URL(string: "https://example.com/image.jpg"),
        newsSite: String = "SpaceNews",
        summary: String = "A rocket was launched successfully.",
        publishedAt: Date = Date(timeIntervalSince1970: 1_700_000_000)
    ) -> Article {
        Article(
            id: id,
            title: title,
            articleURL: articleURL,
            imageURL: imageURL,
            newsSite: newsSite,
            summary: summary,
            publishedAt: publishedAt
        )
    }
}
