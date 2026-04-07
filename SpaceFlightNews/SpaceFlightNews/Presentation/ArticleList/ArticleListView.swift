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
            VStack(spacing: 0) {
                // Title anchored 15pt from the top safe area edge.
                // .ignoresSafeArea(.keyboard) prevents the keyboard from
                // pushing the VStack up and shifting the title position.
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
        .navigationDestination(for: Article.self) { article in
            ArticleDetailView(viewModel: makeDetailViewModel(article))
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
            Text("No se encontraron artículos con ese título.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
