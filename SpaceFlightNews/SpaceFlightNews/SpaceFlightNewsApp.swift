// App/SpaceFlightNewsApp.swift
// Entry point. Creates AppDependencies once and injects into the root view.

import SwiftUI

@main
struct SpaceFlightNewsApp: App {

    @State private var dependencies = AppDependencies()

    var body: some Scene {
        WindowGroup {
            ArticleListView(viewModel: dependencies.articleListViewModel)
        }
    }
}
