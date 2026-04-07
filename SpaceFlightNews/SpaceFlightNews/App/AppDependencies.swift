// App/AppDependencies.swift
// Composition root. Wires all layers together manually — no DI framework.
// Single source of truth for object lifetimes.

import Foundation

@MainActor
final class AppDependencies {

    // MARK: - Shared ViewModels

    let articleListViewModel: ArticleListViewModel

    // MARK: - Stored use cases (for ViewModel factories)

    private let fetchArticleDetailUseCase: any FetchArticleDetailUseCaseProtocol

    // MARK: - Init

    init() {
        let apiClient  = URLSessionAPIClient()
        let repository = ArticleRepositoryImpl(apiClient: apiClient)

        let fetchArticlesUseCase    = FetchArticlesUseCase(repository: repository)
        let fetchArticleDetailUseCase = FetchArticleDetailUseCase(repository: repository)

        self.fetchArticleDetailUseCase = fetchArticleDetailUseCase
        self.articleListViewModel = ArticleListViewModel(
            fetchArticlesUseCase: fetchArticlesUseCase
        )
    }

    // MARK: - ViewModel factories

    /// Creates a new ArticleDetailViewModel for each navigation push.
    /// The article already in memory; the use case re-fetches if needed.
    func makeDetailViewModel(article: Article) -> ArticleDetailViewModel {
        ArticleDetailViewModel(
            article: article,
            fetchArticleDetailUseCase: fetchArticleDetailUseCase
        )
    }
}
