// Presentation/ArticleList/ArticleListViewModel.swift
// Owns the article list state. Handles search debounce + pagination.
//
// currentTask is internal (not private) so unit tests can
// `await viewModel.currentTask?.value` for deterministic assertions
// instead of using fragile Task.yield() or arbitrary sleeps.

import Foundation

@MainActor
final class ArticleListViewModel: ObservableObject {

    // MARK: - Published state

    @Published private(set) var state: ViewState<[Article]> = .idle

    // MARK: - Internal (test access)

    private(set) var currentTask: Task<Void, Never>?

    // MARK: - Private

    private let fetchArticlesUseCase: any FetchArticlesUseCaseProtocol

    private var allArticles: [Article] = []
    private var currentOffset = 0
    private var canLoadMore = true
    private var searchQuery = ""

    private let pageSize = 20
    private let debounceMilliseconds: UInt64 = 400

    // MARK: - Init

    init(fetchArticlesUseCase: some FetchArticlesUseCaseProtocol) {
        self.fetchArticlesUseCase = fetchArticlesUseCase
    }

    // MARK: - Public interface

    /// Call from View.onAppear — loads first page only if not already started.
    func onAppear() {
        guard case .idle = state else { return }
        scheduleLoad()
    }

    /// Called on every search text change. Debounces and resets pagination.
    func search(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard trimmed != searchQuery else { return }
        searchQuery = trimmed
        reset()
        currentTask?.cancel()
        currentTask = Task {
            try? await Task.sleep(nanoseconds: debounceMilliseconds * 1_000_000)
            guard !Task.isCancelled else { return }
            await fetchPage()
        }
    }

    /// Called when the last visible row appears — triggers next page load.
    func loadNextPageIfNeeded(currentArticle: Article) {
        guard canLoadMore,
              case .success(let articles) = state,
              articles.last?.id == currentArticle.id,
              currentTask?.isCancelled != false else { return }
        scheduleLoad()
    }

    /// Resets state and retries from scratch.
    func retry() {
        reset()
        state = .idle
        scheduleLoad()
    }

    // MARK: - Private helpers

    private func scheduleLoad() {
        currentTask?.cancel()
        currentTask = Task { await fetchPage() }
    }

    private func reset() {
        allArticles = []
        currentOffset = 0
        canLoadMore = true
    }

    private func fetchPage() async {
        guard !Task.isCancelled else { return }

        if allArticles.isEmpty { state = .loading }

        do {
            let page = try await fetchArticlesUseCase.execute(
                search: searchQuery.isEmpty ? nil : searchQuery,
                limit: pageSize,
                offset: currentOffset
            )

            guard !Task.isCancelled else { return }

            allArticles += page
            canLoadMore = page.count == pageSize
            currentOffset += page.count
            state = allArticles.isEmpty ? .empty : .success(allArticles)

        } catch let error as AppError {
            guard !Task.isCancelled else { return }
            AppLogger.uiError(error, context: "ArticleListViewModel")
            if allArticles.isEmpty { state = .error(error) }

        } catch {
            guard !Task.isCancelled else { return }
            let appError = AppError.unknown(error)
            AppLogger.uiError(appError, context: "ArticleListViewModel")
            if allArticles.isEmpty { state = .error(appError) }
        }
    }
}
