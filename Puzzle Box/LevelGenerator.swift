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
        
        let walls = generateWalls(count: numWalls, mazeSize: mazeSize, difficulty: difficulty)
        let holes = generateHoles(count: numHoles, walls: walls, mazeSize: mazeSize)
        let balls = isFirstLayer ? generateBalls(count: numBalls) : []
        
        return MazeLayer(walls: walls, holes: holes, initialBalls: balls)
    }
    
    private func generateWalls(count: Int, mazeSize: CGFloat, difficulty: Int) -> [Wall] {
        var walls: [Wall] = []
        let wallThickness: CGFloat = 4
        let minParallelDistance: CGFloat = 60 // Minimum distance between parallel walls
        let maxAttempts = 50
        let includeReverseWall = difficulty >= 2 // Level 3+ (difficulty starts at 0)
        let includeMagnetWall = difficulty >= 4 // Level 5+
        
        for i in 0..<count {
            var validWall: Wall?
            var attempts = 0
            
            // First wall should be reverse wall if applicable (level 3+)
            // Second wall should be magnet wall if applicable (level 5+)
            let shouldBeReverse = includeReverseWall && i == 0
            let shouldBeMagnet = includeMagnetWall && i == 1
            
            while validWall == nil && attempts < maxAttempts {
                let isHorizontal = Bool.random()
                let candidateWall: Wall
                
                if isHorizontal {
                    let y = CGFloat.random(in: 50...(mazeSize - 50))
                    let x = CGFloat.random(in: 0...(mazeSize * 0.6))
                    let width: CGFloat
                    let wallType: WallType
                    
                    if shouldBeReverse {
                        width = CGFloat.random(in: 50...125)
                        wallType = .reverse
                    } else if shouldBeMagnet {
                        width = CGFloat.random(in: 25...62.5) // 1/4 normal length
                        wallType = .magnet
                    } else {
                        width = CGFloat.random(in: 100...250)
                        wallType = .normal
                    }
                    
                    let rect = CGRect(x: x, y: y, width: width, height: wallThickness)
                    candidateWall = Wall(rect: rect, type: wallType)
                } else {
                    let x = CGFloat.random(in: 50...(mazeSize - 50))
                    let y = CGFloat.random(in: 0...(mazeSize * 0.6))
                    let height: CGFloat
                    let wallType: WallType
                    
                    if shouldBeReverse {
                        height = CGFloat.random(in: 50...125)
                        wallType = .reverse
                    } else if shouldBeMagnet {
                        height = CGFloat.random(in: 25...62.5) // 1/4 normal length
                        wallType = .magnet
                    } else {
                        height = CGFloat.random(in: 100...250)
                        wallType = .normal
                    }
                    
                    let rect = CGRect(x: x, y: y, width: wallThickness, height: height)
                    candidateWall = Wall(rect: rect, type: wallType)
                }
                
                if isValidWallPlacement(candidateWall, existingWalls: walls, minParallelDistance: minParallelDistance) {
                    validWall = candidateWall
                }
                
                attempts += 1
            }
            
            if let wall = validWall {
                walls.append(wall)
            }
        }
        
        return walls
    }
    
    private func isValidWallPlacement(_ wall: Wall, existingWalls: [Wall], minParallelDistance: CGFloat) -> Bool {
        let isHorizontal = wall.rect.width > wall.rect.height
        
        for existingWall in existingWalls {
            let existingIsHorizontal = existingWall.rect.width > existingWall.rect.height
            
            // Check if walls are parallel (both horizontal or both vertical)
            if isHorizontal == existingIsHorizontal {
                let distance: CGFloat
                
                if isHorizontal {
                    // For horizontal walls, check vertical distance
                    distance = abs(wall.rect.midY - existingWall.rect.midY)
                    
                    // Also check if they overlap horizontally
                    let horizontalOverlap = !(wall.rect.maxX < existingWall.rect.minX ||
                                             wall.rect.minX > existingWall.rect.maxX)
                    
                    if horizontalOverlap && distance < minParallelDistance {
                        return false
                    }
                } else {
                    // For vertical walls, check horizontal distance
                    distance = abs(wall.rect.midX - existingWall.rect.midX)
                    
                    // Also check if they overlap vertically
                    let verticalOverlap = !(wall.rect.maxY < existingWall.rect.minY ||
                                           wall.rect.minY > existingWall.rect.maxY)
                    
                    if verticalOverlap && distance < minParallelDistance {
                        return false
                    }
                }
            }
            // Perpendicular walls are allowed to be close, so we don't check them
        }
        
        return true
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
            
            // Regular walls need 30 points clearance
            if wall.type != .magnet && dist < 30 {
                return false
            }
            
            // Magnet walls need 150+ points clearance (outside magnetic range)
            if wall.type == .magnet && dist < 150 {
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
