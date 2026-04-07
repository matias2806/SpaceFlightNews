// Presentation/ArticleDetail/ArticleDetailViewModel.swift
// TODO: full implementation in feat: article detail screen commit.

import Foundation

@MainActor
final class ArticleDetailViewModel: ObservableObject {

    @Published private(set) var article: Article

    private let fetchArticleDetailUseCase: any FetchArticleDetailUseCaseProtocol

    init(article: Article, fetchArticleDetailUseCase: some FetchArticleDetailUseCaseProtocol) {
        self.article = article
        self.fetchArticleDetailUseCase = fetchArticleDetailUseCase
    }
}
