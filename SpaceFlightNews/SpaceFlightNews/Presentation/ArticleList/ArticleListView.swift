// Presentation/ArticleList/ArticleListView.swift
// Title is a fixed Text inside the view — never scrolls away.
// Nav bar is empty (.navigationTitle("")) so no large/inline title
// collapsing issues. .searchable persists across all states.

import SwiftUI

struct ArticleListView: View {

    var viewModel: ArticleListViewModel
    var makeDetailViewModel: (Article) -> ArticleDetailViewModel
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack {
                Text("Space Flight News")
                    .font(.title.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 15)
                    .padding(.bottom, 10)

                stateContent
            }
            .ignoresSafeArea(.keyboard)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Buscar por título")
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
            // Distinguish: API returned nothing vs search found nothing
            if viewModel.searchQuery.isEmpty {
                noContentView
            } else {
                searchEmptyView
            }

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

            if viewModel.isLoadingNextPage {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .refreshable { await viewModel.refresh() }
        .navigationDestination(for: Article.self) { article in
            ArticleDetailView(viewModel: makeDetailViewModel(article))
        }
    }

    // MARK: - Empty states

    /// API returned no articles — pull to retry.
    private var noContentView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "newspaper")
                    .font(.system(size: 52))
                    .foregroundStyle(.secondary)
                Text("No hay noticias publicadas")
                    .font(.headline)
                Text("Por favor, vuelve a intentarlo")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
            .frame(maxWidth: .infinity, minHeight: 300)
        }
        .refreshable { await viewModel.refresh() }
    }

    /// Search query returned no matches.
    private var searchEmptyView: some View {
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
