// App/AppDependencies.swift
// Composition root. Wires all layers together manually — no DI framework.
// Single source of truth for object lifetimes.

import Foundation

@MainActor
final class AppDependencies {

    // MARK: - Shared ViewModels

    let articleListViewModel: ArticleListViewModel

    // MARK: - Init

    init() {
        let apiClient  = URLSessionAPIClient()
        let repository = ArticleRepositoryImpl(apiClient: apiClient)

        self.articleListViewModel = ArticleListViewModel(
            fetchArticlesUseCase: FetchArticlesUseCase(repository: repository)
        )
    }

    // MARK: - ViewModel factories

    func makeDetailViewModel(article: Article) -> ArticleDetailViewModel {
        ArticleDetailViewModel(article: article)
    }
}
