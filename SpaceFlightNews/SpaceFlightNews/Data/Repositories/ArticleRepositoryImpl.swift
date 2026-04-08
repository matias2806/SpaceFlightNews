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
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.unknown
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
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.unknown
        }
    }

    func fetchArticle(id: Int) async throws -> Article {
        do {
            let dto: ArticleDTO = try await apiClient.fetch(.articleDetail(id: id))
            return try ArticleMapper.toDomain(dto)
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.unknown
        }
    }
}
