// Presentation/ArticleList/ArticleListViewModel.swift
// Pagination uses the API's "next" cursor URL — avoids duplicates
// if new articles are published between page requests.
//
// isLoadingNextPage replaces the (buggy) `currentTask == nil` guard:
// a completed Task is neither nil nor cancelled, which caused the
// second page to never trigger. A plain Bool is unambiguous.
//
// currentTask remains internal for test determinism:
// `await viewModel.currentTask?.value` gives a clean await point.

import Foundation
import Observation

@Observable
@MainActor
final class ArticleListViewModel {

    // MARK: - Observable state

    private(set) var state: ViewState<[Article]> = .idle
    private(set) var isLoadingNextPage = false
    private(set) var hasNextPage = false

    // MARK: - Internal (test access)

    private(set) var currentTask: Task<Void, Never>?

    // MARK: - Private

    private let fetchArticlesUseCase: any FetchArticlesUseCaseProtocol

    private var allArticles: [Article] = []
    private var nextPageURL: String?       // API cursor — nil means last page
    private(set) var searchQuery = ""      // internal for tests

    private let pageSize = 20

    // MARK: - Init

    init(fetchArticlesUseCase: some FetchArticlesUseCaseProtocol) {
        self.fetchArticlesUseCase = fetchArticlesUseCase
    }

    // MARK: - Public interface

    func onAppear() {
        guard case .idle = state else { return }
        scheduleFirstPage()
    }

    /// Client-side title filter — instant, no network call.
    func search(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard trimmed != searchQuery else { return }
        searchQuery = trimmed
        applyFilter()
    }

    /// Triggers next page when the last visible article appears.
    func loadNextPageIfNeeded(currentArticle: Article) {
        guard searchQuery.isEmpty,          // client-side filter: no more pages needed
              hasNextPage,
              !isLoadingNextPage,           // ← the actual fix: plain Bool, unambiguous
              case .success(let articles) = state,
              articles.last?.id == currentArticle.id else { return }
        scheduleNextPage()
    }

    func retry() {
        allArticles = []
        nextPageURL = nil
        hasNextPage = false
        searchQuery = ""
        state = .idle
        scheduleFirstPage()
    }

    // MARK: - Private

    private func scheduleFirstPage() {
        currentTask?.cancel()
        currentTask = Task { await fetchPage(nextPageURL: nil) }
    }

    private func scheduleNextPage() {
        currentTask?.cancel()
        currentTask = Task { await fetchPage(nextPageURL: nextPageURL) }
    }

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

    private func fetchPage(nextPageURL cursorURL: String?) async {
        guard !Task.isCancelled else { return }

        if allArticles.isEmpty { state = .loading }
        isLoadingNextPage = true
        defer {
            isLoadingNextPage = false
            currentTask = nil     // reset so next trigger can fire
        }

        do {
            let result = try await fetchArticlesUseCase.execute(
                nextPageURL: cursorURL,
                search: nil,        // search is client-side
                limit: pageSize
            )

            guard !Task.isCancelled else { return }

            allArticles += result.articles
            nextPageURL = result.nextPageURL
            hasNextPage = result.nextPageURL != nil
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
