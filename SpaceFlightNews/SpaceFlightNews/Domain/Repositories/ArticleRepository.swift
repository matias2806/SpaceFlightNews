// Domain/Repositories/ArticleRepository.swift
// Protocol only. Domain defines the contract; Data provides the implementation.

import Foundation

protocol ArticleRepository: Sendable {
    /// First page or search reset — always starts from offset 0.
    func fetchArticles(search: String?, limit: Int) async throws -> ArticlePageResult

    /// Follows the API's "next" cursor URL to fetch the next page.
    /// Using the cursor avoids duplicates if new articles are published between requests.
    func fetchNextPage(url: String) async throws -> ArticlePageResult
}
