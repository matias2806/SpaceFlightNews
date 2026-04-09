// Data/ArticleMapperTests.swift
// Tests for ArticleMapper — pure functions, no async needed.

import XCTest
@testable import SpaceFlightNews

final class ArticleMapperTests: XCTestCase {

    // MARK: - Single DTO mapping

    func test_toDomain_validDTO_mapsAllFields() throws {
        let dto = ArticleDTO.stub(
            id: 42,
            title: "Mars Mission",
            url: "https://example.com/mars",
            imageUrl: "https://example.com/mars.jpg",
            newsSite: "NASANews",
            summary: "Humans will go to Mars.",
            publishedAt: "2024-06-15T12:00:00Z"
        )

        let article = try ArticleMapper.toDomain(dto)

        XCTAssertEqual(article.id, 42)
        XCTAssertEqual(article.title, "Mars Mission")
        XCTAssertEqual(article.articleURL, URL(string: "https://example.com/mars"))
        XCTAssertEqual(article.imageURL, URL(string: "https://example.com/mars.jpg"))
        XCTAssertEqual(article.newsSite, "NASANews")
        XCTAssertEqual(article.summary, "Humans will go to Mars.")
    }

    func test_toDomain_invalidArticleURL_throwsDataCorrupted() {
        let dto = ArticleDTO.stub(url: "not a valid url ://")

        XCTAssertThrowsError(try ArticleMapper.toDomain(dto)) { error in
            XCTAssertEqual(error as? AppError, .dataCorrupted)
        }
    }

    func test_toDomain_nilImageURL_mapsToNil() throws {
        let dto = ArticleDTO.stub(imageUrl: nil)
        let article = try ArticleMapper.toDomain(dto)
        XCTAssertNil(article.imageURL)
    }

    func test_toDomain_invalidImageURL_mapsToNil() throws {
        let dto = ArticleDTO.stub(imageUrl: "not a url")
        let article = try ArticleMapper.toDomain(dto)
        // Invalid image URL becomes nil (non-fatal — article still usable)
        XCTAssertNil(article.imageURL)
    }

    // MARK: - Date parsing

    func test_toDomain_iso8601Date_parsesCorrectly() throws {
        let dto = ArticleDTO.stub(publishedAt: "2024-06-15T12:00:00Z")
        let article = try ArticleMapper.toDomain(dto)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: article.publishedAt)

        XCTAssertEqual(components.year, 2024)
        XCTAssertEqual(components.month, 6)
        XCTAssertEqual(components.day, 15)
        XCTAssertEqual(components.hour, 12)
    }

    func test_toDomain_iso8601DateWithFractionalSeconds_parsesCorrectly() throws {
        let dto = ArticleDTO.stub(publishedAt: "2024-06-15T12:00:00.000Z")
        let article = try ArticleMapper.toDomain(dto)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: article.publishedAt)

        XCTAssertEqual(components.year, 2024)
        XCTAssertEqual(components.month, 6)
        XCTAssertEqual(components.day, 15)
        XCTAssertEqual(components.hour, 12)
    }

    func test_toDomain_unparsableDate_fallsBackToDistantPast() throws {
        let dto = ArticleDTO.stub(publishedAt: "not-a-date")
        let article = try ArticleMapper.toDomain(dto)
        XCTAssertEqual(article.publishedAt, .distantPast)
    }

    // MARK: - List mapping

    func test_toDomain_list_mapsAllValidItems() {
        let dtos = [ArticleDTO.stub(id: 1), ArticleDTO.stub(id: 2), ArticleDTO.stub(id: 3)]
        let articles = ArticleMapper.toDomain(dtos)
        XCTAssertEqual(articles.count, 3)
    }

    func test_toDomain_list_skipsBadURLsWithoutFailing() {
        let dtos = [
            ArticleDTO.stub(id: 1),
            ArticleDTO.stub(id: 2, url: "bad url"),   // invalid — should be skipped
            ArticleDTO.stub(id: 3)
        ]
        let articles = ArticleMapper.toDomain(dtos)
        XCTAssertEqual(articles.count, 2)
        XCTAssertEqual(articles[0].id, 1)
        XCTAssertEqual(articles[1].id, 3)
    }

    func test_toDomain_emptyList_returnsEmpty() {
        let articles = ArticleMapper.toDomain([])
        XCTAssertTrue(articles.isEmpty)
    }

    // MARK: - Performance

    func test_performance_mapping100DTOs() {
        let dtos = (0..<100).map { ArticleDTO.stub(id: $0) }
        measure {
            _ = ArticleMapper.toDomain(dtos)
        }
    }
}
