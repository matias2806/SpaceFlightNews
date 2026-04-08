// Presentation/ArticleList/ArticleListView.swift
//
// Why .toolbar(.hidden, for: .navigationBar):
//   SwiftUI's List is a UICollectionView. UIKit automatically adds a content
//   inset equal to the nav-bar height to any scroll view inside a
//   UINavigationController — regardless of the scroll view's frame position
//   in the layout. With a nav bar present, the UIRefreshControl anchors above
//   the List frame (in the title area), where the title's background hides it.
//   Hiding the nav bar removes that automatic inset: the List starts exactly
//   where VStack places it and the pull-to-refresh spinner appears just below
//   the title, where the user can see it.
//
//   ArticleDetailView re-enables the nav bar (.toolbar(.visible)) so the
//   standard back button appears on push.
//
// Search bar is only visible when there are articles to search through,
// or when a search is already active (so the user can clear it).

import SwiftUI

struct ArticleListView: View {

    var viewModel: ArticleListViewModel
    var makeDetailViewModel: (Article) -> ArticleDetailViewModel
    @State private var searchText = ""

    private var shouldShowSearch: Bool {
        switch viewModel.state {
        case .success:                                    return true
        case .empty where !viewModel.searchQuery.isEmpty: return true
        default:                                          return false
        }
    }

    var body: some View {
        NavigationStack {
            if shouldShowSearch {
                mainContent
                    .searchable(text: $searchText, prompt: "Buscar por título")
                    .onChange(of: searchText) { _, query in viewModel.search(query) }
                    .onChange(of: viewModel.searchQuery) { _, query in
                        if query.isEmpty { searchText = "" }
                    }
            } else {
                mainContent
            }
        }
        .onAppear { viewModel.onAppear() }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            Text("Space Flight News")
                .font(.title.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 15)
                .padding(.bottom, 10)

            stateContent
        }
        // Hiding the nav bar removes UIKit's automatic scroll-view content
        // inset, so the List frame and the pull-to-refresh origin align.
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: Article.self) { article in
            ArticleDetailView(viewModel: makeDetailViewModel(article))
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
    }

    // MARK: - Empty states

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
