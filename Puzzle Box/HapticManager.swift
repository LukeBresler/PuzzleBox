//
//  HapticFeedbackProvider.swift
//  Puzzle Box
//
//  Created by Luke Bresler on 2026/01/17.
//


//
//  HapticManager.swift
//  Puzzle Box
//

import UIKit

// MARK: - Haptic Feedback Protocol

protocol HapticFeedbackProvider {
    func wallHit(intensity: CGFloat)
    func boundaryHit()
    func holeSuccess()
}

// MARK: - Haptic Manager

final class HapticManager: HapticFeedbackProvider {
    static let shared = HapticManager()
    
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationFeedback = UINotificationFeedbackGenerator()
    
    private init() {
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        notificationFeedback.prepare()
    }
    
    func wallHit(intensity: CGFloat) {
        if intensity > 5 {
            mediumImpact.impactOccurred()
        } else if intensity > 2 {
            lightImpact.impactOccurred()
        }
    }
    
    func boundaryHit() {
        heavyImpact.impactOccurred()
    }
    
    func holeSuccess() {
        notificationFeedback.notificationOccurred(.success)
    }
}