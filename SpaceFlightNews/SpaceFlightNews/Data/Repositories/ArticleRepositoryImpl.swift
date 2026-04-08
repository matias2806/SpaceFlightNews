// Data/Repositories/ArticleRepositoryImpl.swift
// Concrete implementation of ArticleRepository (Domain protocol).

import Foundation

final class ArticleRepositoryImpl: ArticleRepository {

    private let apiClient: any APIClientProtocol

    init(apiClient: some APIClientProtocol) {
        self.apiClient = apiClient
    }

    // MARK: - ArticleRepository

    func fetchArticles(search: String?, limit: Int) async throws -> ArticlePageResult {
        do {
            let response: ArticleListDTO = try await apiClient.fetch(
                .articles(search: search, limit: limit)
            )
            return ArticlePageResult(
                articles: ArticleMapper.toDomain(response.results),
                nextPageURL: response.next
            )
        } catch {
            throw (error as? AppError) ?? .unknown
        }
    }

    func fetchNextPage(url: String) async throws -> ArticlePageResult {
        guard let pageURL = URL(string: url) else {
            throw AppError.unknown
        }
        do {
            let response: ArticleListDTO = try await apiClient.fetch(.nextPage(url: pageURL))
            return ArticlePageResult(
                articles: ArticleMapper.toDomain(response.results),
                nextPageURL: response.next
            )
        } catch {
            throw (error as? AppError) ?? .unknown
        }
    }
}
