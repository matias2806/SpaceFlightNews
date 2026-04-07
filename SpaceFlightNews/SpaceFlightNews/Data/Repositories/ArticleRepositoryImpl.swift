// Data/Repositories/ArticleRepositoryImpl.swift
// Concrete implementation of the ArticleRepository protocol (defined in Domain).
// Only this file knows about APIClient, DTOs, and ArticleMapper —
// Domain and Presentation never import anything from Data directly.

import Foundation

final class ArticleRepositoryImpl: ArticleRepository {

    private let apiClient: any APIClientProtocol

    init(apiClient: some APIClientProtocol) {
        self.apiClient = apiClient
    }

    // MARK: - ArticleRepository

    func fetchArticles(search: String?, limit: Int, offset: Int) async throws -> [Article] {
        do {
            let response: ArticleListDTO = try await apiClient.fetch(
                .articles(search: search, limit: limit, offset: offset)
            )
            return ArticleMapper.toDomain(response.results)
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.unknown(error)
        }
    }

    func fetchArticle(id: Int) async throws -> Article {
        do {
            let dto: ArticleDTO = try await apiClient.fetch(.articleDetail(id: id))
            return try ArticleMapper.toDomain(dto)
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.unknown(error)
        }
    }
}
