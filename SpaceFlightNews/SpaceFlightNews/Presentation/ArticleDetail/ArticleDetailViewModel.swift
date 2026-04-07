// Presentation/ArticleDetail/ArticleDetailViewModel.swift
// TODO: full implementation in feat: article detail screen commit.

import Foundation
import Observation

@Observable
@MainActor
final class ArticleDetailViewModel {

    private(set) var article: Article

    private let fetchArticleDetailUseCase: any FetchArticleDetailUseCaseProtocol

    init(article: Article, fetchArticleDetailUseCase: some FetchArticleDetailUseCaseProtocol) {
        self.article = article
        self.fetchArticleDetailUseCase = fetchArticleDetailUseCase
    }
}
