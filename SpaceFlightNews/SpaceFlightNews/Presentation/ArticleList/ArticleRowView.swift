// Presentation/ArticleList/ArticleRowView.swift
// Single row: thumbnail + title + source + date.
// dateFormatter is static to avoid reinstantiation per cell.

import SwiftUI

struct ArticleRowView: View {

    let article: Article

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            thumbnail

            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.headline)
                    .lineLimit(3)

                Text(article.newsSite)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(Self.dateFormatter.string(from: article.publishedAt))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    private var thumbnail: some View {
        Group {
            if let imageURL = article.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholderImage
                    case .empty:
                        ProgressView()
                    @unknown default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .background(Color(.systemGray5).clipShape(RoundedRectangle(cornerRadius: 8)))
    }

    private var placeholderImage: some View {
        Image(systemName: "newspaper")
            .font(.title2)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
