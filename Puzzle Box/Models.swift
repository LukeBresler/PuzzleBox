//
//  Models.swift
//  Puzzle Box
//

import Foundation
import CoreGraphics

// MARK: - Ball

struct Ball: Identifiable {
    let id: Int
    var position: CGPoint
    var velocity: CGPoint
    var isCompleted: Bool = false
}

// MARK: - Wall

enum WallType {
    case normal
    case reverse
    case magnet
}

struct Wall {
    let rect: CGRect
    let type: WallType
    
    init(rect: CGRect, type: WallType = .normal) {
        self.rect = rect
        self.type = type
    }
}

// MARK: - Hole

struct Hole {
    let position: CGPoint
    let radius: CGFloat = 12
}

// MARK: - MazeLayer

struct MazeLayer {
    let walls: [Wall]
    let holes: [Hole]
    var initialBalls: [Ball]
}

// MARK: - Level

struct Level {
    let name: String
    let layers: [MazeLayer]
}
