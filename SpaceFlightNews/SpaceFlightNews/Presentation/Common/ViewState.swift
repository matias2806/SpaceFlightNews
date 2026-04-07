// Presentation/Common/ViewState.swift
// Generic state enum shared by all ViewModels.
// Equatable conformance is conditional on T: Equatable —
// lets tests do XCTAssertEqual(viewModel.state, .success([...])).

import Foundation

enum ViewState<T: Sendable>: Sendable {
    case idle
    case loading
    case success(T)
    case empty
    case error(AppError)
}

extension ViewState: Equatable where T: Equatable {}
