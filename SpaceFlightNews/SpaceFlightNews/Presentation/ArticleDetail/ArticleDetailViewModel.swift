// Presentation/ArticleDetail/ArticleDetailViewModel.swift
// The article arrives already populated from the list — no additional
// network call is needed since the API detail endpoint returns the same fields.

import Foundation
import Observation

@Observable
@MainActor
final class ArticleDetailViewModel {
    let article: Article

    init(article: Article) {
        self.article = article
    }
}
