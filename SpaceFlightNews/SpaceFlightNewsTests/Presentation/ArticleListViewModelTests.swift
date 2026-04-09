// Presentation/ArticleListViewModelTests.swift
// Tests for ArticleListViewModel state transitions.
//
// Determinism strategy: `await sut.currentTask?.value` blocks until
// the in-flight Task completes — no Task.yield(), no arbitrary sleeps.
// currentTask is set to nil in defer{} at the end of fetchPage(),
// so awaiting it gives a clean synchronisation point.

import XCTest
@testable import SpaceFlightNews

@MainActor
final class ArticleListViewModelTests: XCTestCase {

    var sut: ArticleListViewModel!
    var mockUseCase: MockFetchArticlesUseCase!

    override func setUp() {
        super.setUp()
        mockUseCase = MockFetchArticlesUseCase()
        sut = ArticleListViewModel(fetchArticlesUseCase: mockUseCase)
    }

    override func tearDown() {
        sut?.currentTask?.cancel()
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    // MARK: - Initial state

    func test_initialState_isIdle() {
        XCTAssertEqual(sut.state, .idle)
        XCTAssertFalse(sut.isLoadingNextPage)
        XCTAssertFalse(sut.hasNextPage)
    }

    // MARK: - onAppear

    func test_onAppear_loadsFirstPage_setsSuccessState() async {
        mockUseCase.stubbedResult = ArticlePageResult(articles: [.stub(id: 1)], nextPageURL: nil)

        sut.onAppear()
        await sut.currentTask?.value

        XCTAssertEqual(sut.state, .success([.stub(id: 1)]))
    }

    func test_onAppear_emptyResult_setsEmptyState() async {
        mockUseCase.stubbedResult = ArticlePageResult(articles: [], nextPageURL: nil)

        sut.onAppear()
        await sut.currentTask?.value

        XCTAssertEqual(sut.state, .empty)
    }

    func test_onAppear_calledTwice_fetchesOnlyOnce() async {
        mockUseCase.stubbedResult = ArticlePageResult(articles: [.stub()], nextPageURL: nil)

        sut.onAppear()
        await sut.currentTask?.value
        sut.onAppear()

        XCTAssertEqual(mockUseCase.callCount, 1)
    }

    // MARK: - Error handling

    func test_onAppear_networkError_setsErrorState() async {
        mockUseCase.stubbedError = AppError.networkUnavailable

        sut.onAppear()
        await sut.currentTask?.value

        XCTAssertEqual(sut.state, .error(.networkUnavailable))
    }

    func test_onAppear_serverError_setsErrorState() async {
        mockUseCase.stubbedError = AppError.serverError(statusCode: 503)

        sut.onAppear()
        await sut.currentTask?.value

        XCTAssertEqual(sut.state, .error(.serverError(statusCode: 503)))
    }

    func test_onAppear_nonAppError_mapsToUnknown() async {
        // Tests the generic `catch { .unknown }` branch — thrown when a non-AppError
        // escapes the use case (e.g. an unexpected system error).
        mockUseCase.stubbedError = NSError(domain: "test", code: -1)

        sut.onAppear()
        await sut.currentTask?.value

        XCTAssertEqual(sut.state, .error(.unknown))
    }

    // MARK: - Retry

    func test_retry_afterError_resetsAndReloads() async {
        mockUseCase.stubbedError = AppError.networkUnavailable
        sut.onAppear()
        await sut.currentTask?.value

        XCTAssertEqual(sut.state, .error(.networkUnavailable))

        mockUseCase.stubbedError = nil
        mockUseCase.stubbedResult = ArticlePageResult(articles: [.stub(id: 1)], nextPageURL: nil)

        sut.retry()
        await sut.currentTask?.value

        XCTAssertEqual(sut.state, .success([.stub(id: 1)]))
        XCTAssertEqual(mockUseCase.callCount, 2)
    }

    func test_retry_clearsSearchQuery() async {
        mockUseCase.stubbedResult = ArticlePageResult(
            articles: [.stub(title: "SpaceX")],
            nextPageURL: nil
        )

        sut.onAppear()
        await sut.currentTask?.value

        sut.search("spacex")
        XCTAssertEqual(sut.searchQuery, "spacex")

        sut.retry()
        await sut.currentTask?.value

        XCTAssertEqual(sut.searchQuery, "")
    }

    // MARK: - Refresh

    func test_refresh_replacesArticles() async {
        // Load page 1 (2 articles) + page 2 (2 more) → 4 total
        let page1 = [Article.stub(id: 1), Article.stub(id: 2)]
        mockUseCase.stubbedResult = ArticlePageResult(articles: page1, nextPageURL: "next")
        sut.onAppear()
        await sut.currentTask?.value

        mockUseCase.stubbedResult = ArticlePageResult(
            articles: [.stub(id: 3), .stub(id: 4)],
            nextPageURL: nil
        )
        sut.loadNextPageIfNeeded(currentArticle: page1.last!)
        await sut.currentTask?.value

        // Refresh: should discard all accumulated articles and return to 1 fresh page
        let refreshed = [Article.stub(id: 5), Article.stub(id: 6)]
        mockUseCase.stubbedResult = ArticlePageResult(articles: refreshed, nextPageURL: nil)
        await sut.refresh()

        XCTAssertEqual(sut.state, .success(refreshed))
        XCTAssertFalse(sut.hasNextPage)
    }

    // MARK: - Search

    func test_search_filtersArticlesByTitle() async {
        let articles = [
            Article.stub(id: 1, title: "SpaceX Falcon 9 Launch"),
            Article.stub(id: 2, title: "NASA Artemis Mission"),
            Article.stub(id: 3, title: "SpaceX Starship Test")
        ]

        mockUseCase.stubbedResult = ArticlePageResult(articles: articles, nextPageURL: nil)

        sut.onAppear()
        await sut.currentTask?.value

        sut.search("spacex")

        guard case .success(let filtered) = sut.state else {
            return XCTFail("Expected .success")
        }

        XCTAssertEqual(filtered.count, 2)
    }

    func test_search_caseInsensitive() async {
        mockUseCase.stubbedResult = ArticlePageResult(
            articles: [.stub(title: "SpaceX Launch")],
            nextPageURL: nil
        )

        sut.onAppear()
        await sut.currentTask?.value

        sut.search("SPACEX")

        XCTAssertEqual(sut.state, .success([.stub(title: "SpaceX Launch")]))
    }

    func test_search_noMatch_setsEmptyState() async {
        mockUseCase.stubbedResult = ArticlePageResult(
            articles: [.stub(title: "Mars Mission")],
            nextPageURL: nil
        )

        sut.onAppear()
        await sut.currentTask?.value

        sut.search("xyz")

        XCTAssertEqual(sut.state, .empty)
    }

    func test_search_clearQuery_restoresFullList() async {
        let articles = [
            Article.stub(id: 1, title: "SpaceX"),
            Article.stub(id: 2, title: "NASA")
        ]

        mockUseCase.stubbedResult = ArticlePageResult(articles: articles, nextPageURL: nil)

        sut.onAppear()
        await sut.currentTask?.value

        sut.search("spacex")
        sut.search("")

        XCTAssertEqual(sut.state, .success(articles))
    }

    func test_search_whitespaceOnly_treatedAsEmpty() async {
        let articles = [Article.stub(id: 1), Article.stub(id: 2)]
        mockUseCase.stubbedResult = ArticlePageResult(articles: articles, nextPageURL: nil)

        sut.onAppear()
        await sut.currentTask?.value

        sut.search("   ")

        // Whitespace-only query is trimmed to "" — full list must remain visible
        XCTAssertEqual(sut.state, .success(articles))
        XCTAssertEqual(sut.searchQuery, "")
    }

    // MARK: - Pagination

    func test_hasNextPage_falseWhenAPIReturnsNilNextURL() async {
        mockUseCase.stubbedResult = ArticlePageResult(
            articles: [.stub()],
            nextPageURL: nil
        )

        sut.onAppear()
        await sut.currentTask?.value

        XCTAssertFalse(sut.hasNextPage)
    }

    func test_loadNextPage_appendsArticles() async {
        let page1 = [Article.stub(id: 1), Article.stub(id: 2)]
        let page2 = [Article.stub(id: 3), Article.stub(id: 4)]

        mockUseCase.stubbedResult = ArticlePageResult(
            articles: page1,
            nextPageURL: "next"
        )

        sut.onAppear()
        await sut.currentTask?.value

        mockUseCase.stubbedResult = ArticlePageResult(
            articles: page2,
            nextPageURL: nil
        )

        sut.loadNextPageIfNeeded(currentArticle: page1.last!)
        await sut.currentTask?.value

        XCTAssertEqual(sut.state, .success(page1 + page2))
    }

    func test_loadNextPageIfNeeded_doesNotTrigger_whenSearchActive() async {
        let articles = [Article.stub(id: 1), Article.stub(id: 2)]
        mockUseCase.stubbedResult = ArticlePageResult(articles: articles, nextPageURL: "next")

        sut.onAppear()
        await sut.currentTask?.value

        sut.search("spacex")
        let callsBefore = mockUseCase.callCount

        // With an active search query the guard `searchQuery.isEmpty` must block pagination
        sut.loadNextPageIfNeeded(currentArticle: articles.last!)

        XCTAssertEqual(mockUseCase.callCount, callsBefore)
    }

    func test_loadNextPageIfNeeded_doesNotTrigger_forNonLastArticle() async {
        let articles = [Article.stub(id: 1), Article.stub(id: 2), Article.stub(id: 3)]
        mockUseCase.stubbedResult = ArticlePageResult(articles: articles, nextPageURL: "next")

        sut.onAppear()
        await sut.currentTask?.value

        let callsBefore = mockUseCase.callCount

        // Passing a non-last article must not trigger the next page fetch
        sut.loadNextPageIfNeeded(currentArticle: articles[0])

        XCTAssertEqual(mockUseCase.callCount, callsBefore)
    }

    // MARK: - Loading state

    func test_isLoadingNextPage_falseAfterFetchCompletes() async {
        mockUseCase.stubbedResult = ArticlePageResult(
            articles: [.stub()],
            nextPageURL: nil
        )

        sut.onAppear()
        await sut.currentTask?.value

        XCTAssertFalse(sut.isLoadingNextPage)
    }
}
