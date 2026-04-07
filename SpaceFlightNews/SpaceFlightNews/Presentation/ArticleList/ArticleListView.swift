// Presentation/ArticleList/ArticleListView.swift
// Main screen: search bar + paginated list.
// .searchable is attached to the List (not to the NavigationStack root)
// so it does NOT propagate to pushed views (ArticleDetailView).

import SwiftUI

struct ArticleListView: View {

    var viewModel: ArticleListViewModel
    var makeDetailViewModel: (Article) -> ArticleDetailViewModel
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            stateContent
                .navigationTitle("Space News")
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

            if canLoadMore {
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
            ArticleDetailView(viewModel: makeDetailViewModel(article))
        }
        // .searchable on the List — scoped to this view only,
        // does not appear on ArticleDetailView when pushed.
        .searchable(text: $searchText, prompt: "Buscar por título")
        .onChange(of: searchText) { _, query in
            viewModel.search(query)
        }
    }

    // MARK: - Helpers

    private var canLoadMore: Bool {
        guard case .success = viewModel.state else { return false }
        return viewModel.currentTask != nil
    }

    // MARK: - Empty state

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Sin resultados")
                .font(.headline)
            Text("No se encontraron artículos con ese título.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
