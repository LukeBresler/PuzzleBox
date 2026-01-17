//
//  MotionInputProvider.swift
//  Puzzle Box
//
//  Created by Luke Bresler on 2026/01/17.
//


//
//  MotionManager.swift
//  Puzzle Box
//

import CoreMotion
import CoreGraphics

// MARK: - Motion Input Protocol

protocol MotionInputProvider {
    var currentTilt: CGPoint { get }
    func startUpdates()
    func stopUpdates()
}

// MARK: - Motion Manager

final class MotionManager: MotionInputProvider {
    private let motionManager = CMMotionManager()
    private(set) var currentTilt: CGPoint = .zero
    
    private let updateInterval: TimeInterval = 1/60
    private let sensitivity: CGFloat = 30
    
    func startUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = updateInterval
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let motion = motion, let self = self else { return }
            
            let pitch = motion.attitude.pitch
            let roll = motion.attitude.roll
            
            self.currentTilt = CGPoint(
                x: CGFloat(roll) * self.sensitivity,
                y: CGFloat(pitch) * self.sensitivity
            )
        }
    }
    
    func stopUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
}