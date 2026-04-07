// Domain/Models/ArticlePageResult.swift
// Wraps a page of articles with the cursor URL for the next page.
// nextPageURL = nil means the API has no more pages (last page reached).

import Foundation

struct ArticlePageResult: Sendable {
    let articles: [Article]
    let nextPageURL: String?   // API's "next" field — nil when no more pages
}
