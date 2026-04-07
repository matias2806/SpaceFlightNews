// Presentation/ArticleDetail/ArticleDetailView.swift
// TODO: full implementation in feat: article detail screen commit.

import SwiftUI

struct ArticleDetailView: View {

    let article: Article

    var body: some View {
        Text(article.title)
            .navigationTitle("Detalle")
            .navigationBarTitleDisplayMode(.inline)
    }
}
