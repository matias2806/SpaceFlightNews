// App/Strings.swift
// Resolves a localization key from Localizable.strings into a value
// compatible with SwiftUI's Text, Button, Label, and searchable(prompt:).
//
// Usage:
//   Text(translate("app.title"))
//   .searchable(prompt: translate("search.prompt"))
//   Button(translate("error.retry"), action: onRetry)
//
// All valid keys are defined in Localizable.strings — that file is the
// single source of truth. Non-SwiftUI consumers (e.g. AppError) use
// String(localized: "key") directly.

import SwiftUI

func translate(_ key: String) -> LocalizedStringKey {
    LocalizedStringKey(key)
}
