// Presentation/ArticleList/ArticleListView.swift
// Main screen: search bar + paginated list.
// State-driven: renders based on viewModel.state, no local async logic.

import SwiftUI

struct ArticleListView: View {

    @StateObject var viewModel: ArticleListViewModel
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            stateContent
                .navigationTitle("Space News")
                .searchable(text: $searchText, prompt: "Buscar artículos")
                .onChange(of: searchText) { _, query in
                    viewModel.search(query)
                }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }

    // MARK: - State content

    @ViewBuilder
    private var stateContent: some View {
        switch viewModel.state {
        case .idle, .loading:
            LoadingView()

        case .success(let articles):
            articleList(articles)

        case .empty:
            emptyView

        case .error(let error):
            ErrorView(error: error, onRetry: viewModel.retry)
        }
    }

    // MARK: - Article list

    private func articleList(_ articles: [Article]) -> some View {
        List {
            ForEach(articles) { article in
                NavigationLink(value: article) {
                    ArticleRowView(article: article)
                }
                .onAppear {
                    viewModel.loadNextPageIfNeeded(currentArticle: article)
                }
            }

            if case .success = viewModel.state, viewModel.currentTask != nil {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: Article.self) { article in
            ArticleDetailView(article: article)
        }
    }

    // MARK: - Empty state

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Sin resultados")
                .font(.headline)
            Text("Probá con otro término de búsqueda.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
