// Presentation/Common/ErrorView.swift
// Reusable error state. Receives an AppError (user-facing copy)
// and a retry closure — no coupling to any ViewModel.

import SwiftUI

struct ErrorView: View {
    let error: AppError
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: iconName)
                .font(.system(size: 52))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text(error.errorDescription ?? "Algo salió mal.")
                    .font(.headline)
                    .multilineTextAlignment(.center)

                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            Button("Reintentar", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var iconName: String {
        switch error {
        case .networkUnavailable: "wifi.exclamationmark"
        case .serverError:        "server.rack"
        default:                  "exclamationmark.triangle"
        }
    }
}
