// Presentation/Common/SplashView.swift

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "scope")
                    .font(.system(size: 72, weight: .thin))
                    .foregroundStyle(.primary)
                Text(translate("app.title"))
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
            }
        }
    }
}
