//
//  TimeManager.swift
//  Health Safety and Compliance
//
//  Created by Anthony Bacon on 03/10/2024.
//

import Foundation
import SwiftUI
import Combine

class TimeManager: ObservableObject {
    @Published var currentTime: String = ""

    private var timer: AnyCancellable?

    init() {
        updateCurrentTime()
        startTimer()
    }

    private func updateCurrentTime() {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        currentTime = formatter.string(from: Date())
    }

    private func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateCurrentTime()
            }
    }
}
