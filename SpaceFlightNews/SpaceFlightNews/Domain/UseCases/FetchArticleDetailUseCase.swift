// Domain/UseCases/FetchArticleDetailUseCase.swift
// Encapsulates the "fetch single article by ID" operation.
// The protocol enables mock injection in unit tests without hitting the network.

import Foundation

protocol FetchArticleDetailUseCaseProtocol: Sendable {
    func execute(id: Int) async throws -> Article
}

final class FetchArticleDetailUseCase: FetchArticleDetailUseCaseProtocol {

    private let repository: any ArticleRepository

    init(repository: some ArticleRepository) {
        self.repository = repository
    }

    func execute(id: Int) async throws -> Article {
        try await repository.fetchArticle(id: id)
    }
}
