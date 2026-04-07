// Presentation/ArticleDetail/ArticleDetailViewModel.swift
// The article arrives already populated from the list — no network call needed
// on appear since the API detail endpoint returns the same fields.
// The use case is injected for testability and future extensibility
// (e.g. force-refresh, additional detail fields).

import Foundation
import Observation

@Observable
@MainActor
final class ArticleDetailViewModel {

    // MARK: - Observable state

    private(set) var article: Article

    // MARK: - Private

    private let fetchArticleDetailUseCase: any FetchArticleDetailUseCaseProtocol

    // MARK: - Init

    init(article: Article, fetchArticleDetailUseCase: some FetchArticleDetailUseCaseProtocol) {
        self.article = article
        self.fetchArticleDetailUseCase = fetchArticleDetailUseCase
    }
}
