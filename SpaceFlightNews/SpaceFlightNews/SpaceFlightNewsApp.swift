// App/SpaceFlightNewsApp.swift
// Entry point. Splash shows only during the very first load — never again.

import SwiftUI

@main
struct SpaceFlightNewsApp: App {

    @State private var dependencies = AppDependencies()
    @State private var splashDismissed = false

    var body: some Scene {
        WindowGroup {
            let vm = dependencies.articleListViewModel
            ZStack {
                ArticleListView(
                    viewModel: vm,
                    makeDetailViewModel: dependencies.makeDetailViewModel
                )

                if !splashDismissed {
                    SplashView()
                        .transition(.opacity)
                }
            }
            .onChange(of: vm.state) { _, state in
                guard !splashDismissed else { return }
                switch state {
                case .success, .empty, .error:
                    withAnimation(.easeOut(duration: 0.4)) { splashDismissed = true }
                default:
                    break
                }
            }
        }
    }
}
