// Domain/FetchArticlesUseCaseTests.swift
// Tests for FetchArticlesUseCase — routing logic between first page and next-page cursor.

import XCTest
@testable import SpaceFlightNews

final class FetchArticlesUseCaseTests: XCTestCase {

    var sut: FetchArticlesUseCase!
    var mockRepository: MockArticleRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockArticleRepository()
        sut = FetchArticlesUseCase(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - Routing

    func test_execute_nilCursor_callsFetchArticles() async throws {
        mockRepository.stubbedPageResult = ArticlePageResult(articles: [.stub()], nextPageURL: nil)

        let result = try await sut.execute(nextPageURL: nil, search: nil, limit: 20)

        XCTAssertEqual(mockRepository.fetchArticlesCallCount, 1)
        XCTAssertEqual(mockRepository.fetchNextPageCallCount, 0)
        XCTAssertEqual(result.articles.count, 1)
    }

    func test_execute_withCursor_callsFetchNextPage() async throws {
        let cursorURL = "https://api.spaceflightnewsapi.net/v4/articles/?limit=20&offset=20"
        mockRepository.stubbedPageResult = ArticlePageResult(articles: [.stub()], nextPageURL: nil)

        _ = try await sut.execute(nextPageURL: cursorURL, search: nil, limit: 20)

        XCTAssertEqual(mockRepository.fetchArticlesCallCount, 0)
        XCTAssertEqual(mockRepository.fetchNextPageCallCount, 1)
        XCTAssertEqual(mockRepository.lastFetchNextPageURL, cursorURL)
    }

    // MARK: - nextPageURL propagation

    func test_execute_returnsNextPageURLFromRepository() async throws {
        let nextURL = "https://api.spaceflightnewsapi.net/v4/articles/?limit=20&offset=20"
        mockRepository.stubbedPageResult = ArticlePageResult(articles: [], nextPageURL: nextURL)

        let result = try await sut.execute(nextPageURL: nil, search: nil, limit: 20)

        XCTAssertEqual(result.nextPageURL, nextURL)
    }

    func test_execute_lastPage_returnsNilNextPageURL() async throws {
        mockRepository.stubbedPageResult = ArticlePageResult(articles: [.stub()], nextPageURL: nil)

        let result = try await sut.execute(nextPageURL: nil, search: nil, limit: 20)

        XCTAssertNil(result.nextPageURL)
    }

    // MARK: - Error propagation

    func test_execute_repositoryThrows_propagatesAppError() async {
        mockRepository.stubbedError = AppError.networkUnavailable

        do {
            _ = try await sut.execute(nextPageURL: nil, search: nil, limit: 20)
            XCTFail("Expected error to be thrown")
        } catch let error as AppError {
            XCTAssertEqual(error, .networkUnavailable)
        } catch {
            XCTFail("Expected AppError, got \(error)")
        }
    }

    func test_execute_repositoryThrows_serverError_propagates() async {
        mockRepository.stubbedError = AppError.serverError(statusCode: 500)

        do {
            _ = try await sut.execute(nextPageURL: nil, search: nil, limit: 20)
            XCTFail("Expected error to be thrown")
        } catch let error as AppError {
            XCTAssertEqual(error, .serverError(statusCode: 500))
        } catch {
            XCTFail("Expected AppError, got \(error)")
        }
    }
}
