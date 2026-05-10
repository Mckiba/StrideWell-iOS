//
//  ConnectivityStore.swift
//  Stridewell
//
//  Global online/offline source of truth backed by NWPathMonitor.
//  Screens read `isOffline` to decide whether to show the offline banner
//  or disable network-dependent actions (e.g. chat send).
//

import Foundation
import Network
import Observation

@Observable
final class ConnectivityStore {

    private(set) var isOffline: Bool = false

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "ConnectivityStore.monitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let offline = path.status != .satisfied
            Task { @MainActor in
                self?.isOffline = offline
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
