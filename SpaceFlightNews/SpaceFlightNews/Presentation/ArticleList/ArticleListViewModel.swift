// Presentation/ArticleList/ArticleListViewModel.swift
// Search is client-side, filtering allArticles by title.
// Rationale: title-only matching is exact and instant (no network round-trip).
// Pagination continues to load pages from the API without any search param.
//
// currentTask is internal (not private) so unit tests can
// `await viewModel.currentTask?.value` for deterministic assertions
// instead of using fragile Task.yield() or arbitrary sleeps.

import Foundation
import Observation

@Observable
@MainActor
final class ArticleListViewModel {

    // MARK: - Observable state

    private(set) var state: ViewState<[Article]> = .idle

    // MARK: - Internal (test access)

    private(set) var currentTask: Task<Void, Never>?

    // MARK: - Private

    private let fetchArticlesUseCase: any FetchArticlesUseCaseProtocol

    private var allArticles: [Article] = []
    private var currentOffset = 0
    private var canLoadMore = true
    private(set) var searchQuery = ""   // internal for tests

    private let pageSize = 20

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

    /// Client-side title filter — instant, no network call, no debounce needed.
    /// Pagination is unaffected: new pages still load in the background.
    func search(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard trimmed != searchQuery else { return }
        searchQuery = trimmed
        applyFilter()
    }

    /// Called when the last visible row appears — triggers next page load.
    /// Only active when search is empty (filtering a subset doesn't need more pages).
    func loadNextPageIfNeeded(currentArticle: Article) {
        guard searchQuery.isEmpty,
              canLoadMore,
              case .success(let articles) = state,
              articles.last?.id == currentArticle.id,
              currentTask == nil || currentTask?.isCancelled == true else { return }
        scheduleLoad()
    }

    /// Resets everything and reloads from scratch.
    func retry() {
        allArticles = []
        currentOffset = 0
        canLoadMore = true
        searchQuery = ""
        state = .idle
        scheduleLoad()
    }

    // MARK: - Private helpers

    private func scheduleLoad() {
        currentTask?.cancel()
        currentTask = Task { await fetchPage() }
    }

    /// Applies the current searchQuery to allArticles and updates state.
    private func applyFilter() {
        if searchQuery.isEmpty {
            state = allArticles.isEmpty ? .idle : .success(allArticles)
        } else {
            let filtered = allArticles.filter {
                $0.title.localizedCaseInsensitiveContains(searchQuery)
            }
            state = filtered.isEmpty ? .empty : .success(filtered)
        }
    }

    private func fetchPage() async {
        guard !Task.isCancelled else { return }

        if allArticles.isEmpty { state = .loading }

        do {
            // No search param — filtering is client-side by title.
            let page = try await fetchArticlesUseCase.execute(
                search: nil,
                limit: pageSize,
                offset: currentOffset
            )

            guard !Task.isCancelled else { return }

            allArticles += page
            canLoadMore = page.count == pageSize
            currentOffset += page.count
            applyFilter()

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
