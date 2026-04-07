// Presentation/Common/LoadingView.swift
// Centralised loading indicator. Swap ProgressView for a skeleton here
// without touching any screen.

import SwiftUI

struct LoadingView: View {
    var body: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
