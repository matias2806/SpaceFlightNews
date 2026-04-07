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
        // Cancelar cualquier task en curso ANTES de liberar
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
