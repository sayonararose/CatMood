//
//  HapticManager.swift
//  CatMood
//

import UIKit

final class HapticManager {
    static let shared = HapticManager()

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationFeedback = UINotificationFeedbackGenerator()

    private var lastHapticTime: Date = .distantPast
    private let minimumInterval: TimeInterval = 0.1

    private init() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        notificationFeedback.prepare()
    }

    func light() {
        guard shouldTriggerHaptic() else { return }
        impactLight.impactOccurred()
        impactLight.prepare()
    }

    func medium() {
        guard shouldTriggerHaptic() else { return }
        impactMedium.impactOccurred()
        impactMedium.prepare()
    }

    func heavy() {
        guard shouldTriggerHaptic() else { return }
        impactHeavy.impactOccurred()
        impactHeavy.prepare()
    }

    func success() {
        guard shouldTriggerHaptic() else { return }
        notificationFeedback.notificationOccurred(.success)
        notificationFeedback.prepare()
    }

    func error() {
        guard shouldTriggerHaptic() else { return }
        notificationFeedback.notificationOccurred(.error)
        notificationFeedback.prepare()
    }

    func warning() {
        guard shouldTriggerHaptic() else { return }
        notificationFeedback.notificationOccurred(.warning)
        notificationFeedback.prepare()
    }

    private func shouldTriggerHaptic() -> Bool {
        let now = Date()
        guard now.timeIntervalSince(lastHapticTime) >= minimumInterval else {
            return false
        }
        lastHapticTime = now
        return true
    }
}
