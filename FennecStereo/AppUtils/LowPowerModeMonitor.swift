//
//  LowPowerModeMonitor.swift
//  FennecStereo
//
//  Created by Kushkumar on 26/11/25.
//
import SwiftUI
import Combine

class LowPowerModeMonitor: ObservableObject {
    @Published var isLowPowerModeEnabled: Bool =
        ProcessInfo.processInfo.isLowPowerModeEnabled

    private var cancellable: AnyCancellable?

    init() {
        // Observe notifications from iOS when Low Power Mode changes
        cancellable = NotificationCenter.default
            .publisher(for: .NSProcessInfoPowerStateDidChange)
            .sink { [weak self] _ in
                self?.isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
            }
    }
}

