// Presentation/ArticleDetail/ArticleDetailView.swift
// Displays full article: hero image, title, source, date, summary, external link.
// State-less from the view perspective — all data comes from the ViewModel.

import SwiftUI

struct ArticleDetailView: View {

    var viewModel: ArticleDetailViewModel

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                heroImage
                contentSection
            }
        }
        // Re-enable the nav bar so the back button appears (the list view hides
        // it to fix the pull-to-refresh content-inset issue).
        .toolbar(.visible, for: .navigationBar)
        .navigationTitle(viewModel.article.newsSite)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Hero image

    private var heroImage: some View {
        Group {
            if let imageURL = viewModel.article.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure, .empty:
                        imagePlaceholder
                    @unknown default:
                        imagePlaceholder
                    }
                }
            } else {
                imagePlaceholder
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .clipped()
    }

    private var imagePlaceholder: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .overlay {
                Image(systemName: "newspaper")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)
            }
    }

    // MARK: - Content

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            Text(viewModel.article.title)
                .font(.title2.bold())
                .fixedSize(horizontal: false, vertical: true)

            // Meta row
            HStack {
                Label(viewModel.article.newsSite, systemImage: "newspaper")
                Spacer()
                Label(
                    Self.dateFormatter.string(from: viewModel.article.publishedAt),
                    systemImage: "calendar"
                )
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Divider()

            // Summary
            Text(viewModel.article.summary)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

            // External link
            Link(destination: viewModel.article.articleURL) {
                Label("Leer artículo completo", systemImage: "safari")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .padding(16)
    }
}
