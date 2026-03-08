//
//  Polling.swift
//  Stridewell
//
//  Shared exponential-backoff polling helper.
//  Used by onboarding screens that need to wait for a server-side state
//  transition (e.g. Strava analysis complete, plan built).
//

import Foundation

enum Polling {

    /// Polls `condition` with exponential back-off until it returns `true`
    /// or the calling Task is cancelled.
    ///
    /// - Parameters:
    ///   - initial: First sleep duration (default 3 s).
    ///   - max:     Maximum sleep duration (default 15 s).
    ///   - step:    Amount added to the delay after each failed check (default 3 s).
    ///   - condition: Async closure; return `true` to stop polling.
    static func exponentialBackoff(
        initial: Duration = .seconds(3),
        max:     Duration = .seconds(15),
        step:    Duration = .seconds(3),
        until condition: () async -> Bool
    ) async {
        var delay = initial
        while !Task.isCancelled {
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            if await condition() { return }
            delay = Swift.min(delay + step, max)
        }
    }
}
