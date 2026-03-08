//
//  LoadableState.swift
//  Stridewell
//
//  Generic screen-state enum shared by all data-loading screens.
//  Replaces the near-identical local `ScreenState` enums that were
//  declared in each screen file.
//
//  Usage:
//      // Screen that stores loaded data in a Store (no associated value)
//      @State private var screenState: LoadableState<Void> = .loading
//      screenState = .loaded   // via the Void convenience below
//
//      // Screen that needs to pass data into the loaded view
//      @State private var screenState: LoadableState<DecisionRecord> = .loading
//      screenState = .loaded(record)
//      case .loaded(let record): myView(record)
//

import Foundation

enum LoadableState<T> {
    case loading
    case loaded(T)
    case empty
    case error(String)
}

// MARK: - Void convenience

extension LoadableState where T == Void {
    /// Shorthand so callers can write `screenState = .loaded` instead of `.loaded(())`.
    static var loaded: Self { .loaded(()) }
}
