//
//  LevelGenerating.swift
//  Puzzle Box
//
//  Created by Luke Bresler on 2026/01/17.
//


//
//  LevelGenerator.swift
//  Puzzle Box
//

import CoreGraphics

// MARK: - Level Generation Protocol

protocol LevelGenerating {
    func generateLevel(difficulty: Int, mazeSize: CGFloat) -> Level
}

// MARK: - Level Generator

final class LevelGenerator: LevelGenerating {
    
    func generateLevel(difficulty: Int, mazeSize: CGFloat) -> Level {
        let numLayers = min(2 + difficulty / 2, 5)
        let numBalls = min(1 + difficulty / 3, 3)
        
        var layers: [MazeLayer] = []
        
        for layerIndex in 0..<numLayers {
            let layer = generateLayer(
                layerIndex: layerIndex,
                difficulty: difficulty,
                numBalls: numBalls,
                mazeSize: mazeSize
            )
            layers.append(layer)
        }
        
        return Level(name: "Level \(difficulty + 1)", layers: layers)
    }
    
    // MARK: - Private Methods
    
    private func generateLayer(
        layerIndex: Int,
        difficulty: Int,
        numBalls: Int,
        mazeSize: CGFloat
    ) -> MazeLayer {
        let isFirstLayer = layerIndex == 0
        let numWalls = 2 + difficulty + Int.random(in: 0...2)
        let numHoles = isFirstLayer ? numBalls : max(1, numBalls - layerIndex)
        
        let walls = generateWalls(count: numWalls, mazeSize: mazeSize)
        let holes = generateHoles(count: numHoles, walls: walls, mazeSize: mazeSize)
        let balls = isFirstLayer ? generateBalls(count: numBalls) : []
        
        return MazeLayer(walls: walls, holes: holes, initialBalls: balls)
    }
    
    private func generateWalls(count: Int, mazeSize: CGFloat) -> [Wall] {
        var walls: [Wall] = []
        
        for _ in 0..<count {
            let isHorizontal = Bool.random()
            let wallThickness: CGFloat = 4
            
            if isHorizontal {
                let y = CGFloat.random(in: 50...(mazeSize - 50))
                let x = CGFloat.random(in: 0...(mazeSize * 0.6))
                let width = CGFloat.random(in: 100...250)
                walls.append(Wall(rect: CGRect(x: x, y: y, width: width, height: wallThickness)))
            } else {
                let x = CGFloat.random(in: 50...(mazeSize - 50))
                let y = CGFloat.random(in: 0...(mazeSize * 0.6))
                let height = CGFloat.random(in: 100...250)
                walls.append(Wall(rect: CGRect(x: x, y: y, width: wallThickness, height: height)))
            }
        }
        
        return walls
    }
    
    private func generateHoles(count: Int, walls: [Wall], mazeSize: CGFloat) -> [Hole] {
        var holes: [Hole] = []
        
        for _ in 0..<count {
            if let hole = findValidHolePosition(walls: walls, existingHoles: holes, mazeSize: mazeSize) {
                holes.append(hole)
            }
        }
        
        // Ensure at least one hole
        if holes.isEmpty {
            holes.append(Hole(position: CGPoint(x: mazeSize * 0.8, y: mazeSize * 0.8)))
        }
        
        return holes
    }
    
    private func findValidHolePosition(
        walls: [Wall],
        existingHoles: [Hole],
        mazeSize: CGFloat
    ) -> Hole? {
        let maxAttempts = 50
        
        for _ in 0..<maxAttempts {
            let position = CGPoint(
                x: CGFloat.random(in: 50...(mazeSize - 50)),
                y: CGFloat.random(in: 50...(mazeSize - 50))
            )
            
            if isValidHolePosition(position, walls: walls, existingHoles: existingHoles) {
                return Hole(position: position)
            }
        }
        
        return nil
    }
    
    private func isValidHolePosition(
        _ position: CGPoint,
        walls: [Wall],
        existingHoles: [Hole]
    ) -> Bool {
        // Check distance from walls
        for wall in walls {
            let closestX = max(wall.rect.minX, min(position.x, wall.rect.maxX))
            let closestY = max(wall.rect.minY, min(position.y, wall.rect.maxY))
            let dist = hypot(position.x - closestX, position.y - closestY)
            if dist < 30 {
                return false
            }
        }
        
        // Check distance from other holes
        for hole in existingHoles {
            if hypot(position.x - hole.position.x, position.y - hole.position.y) < 40 {
                return false
            }
        }
        
        return true
    }
    
    private func generateBalls(count: Int) -> [Ball] {
        var balls: [Ball] = []
        
        for i in 0..<count {
            let ballPos = CGPoint(
                x: 30 + CGFloat(i * 40),
                y: 30 + CGFloat(i * 30)
            )
            balls.append(Ball(id: i, position: ballPos, velocity: .zero))
        }
        
        return balls
    }
}