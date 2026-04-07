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
    
    // Cambiar la declaración de currentTask
    nonisolated(unsafe) private(set) var currentTask: Task<Void, Never>?
    
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
    
    deinit {
        currentTask?.cancel()
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

    /// Pull-to-refresh: re-fetches from page 1 preserving the active search query.
    /// Returns only after the fetch completes so the refresh spinner dismisses correctly.
    func refresh() async {
        allArticles = []
        nextPageURL = nil
        hasNextPage = false
        scheduleFirstPage()
        await currentTask?.value
    }
    
    // MARK: - Private
    
    private func scheduleFirstPage() {
        currentTask?.cancel()
        currentTask = Task { [weak self] in
            await self?.fetchPage(nextPageURL: nil)
        }
    }
    
    private func scheduleNextPage() {
        currentTask?.cancel()
        let cursor = nextPageURL        // capture URL at schedule time
        currentTask = Task { [weak self] in
            await self?.fetchPage(nextPageURL: cursor)
        }
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
            currentTask = nil
        }

        do {
            let result = try await fetchArticlesUseCase.execute(
                nextPageURL: cursorURL,
                search: nil,
                limit: pageSize
            )

            guard !Task.isCancelled else { return }

            allArticles += result.articles
            nextPageURL = result.nextPageURL
            hasNextPage = result.nextPageURL != nil
            applyFilter()
            
            if allArticles.isEmpty { state = .empty }
            
        } catch let error as AppError {
            guard !Task.isCancelled else { return }
            AppLogger.uiError(error, context: "ArticleListViewModel")
            if allArticles.isEmpty { state = .error(error) }

        } catch {
            guard !Task.isCancelled else { return }
            AppLogger.uiError(.unknown, context: "ArticleListViewModel")
            if allArticles.isEmpty { state = .error(.unknown) }
        }
    }
}
