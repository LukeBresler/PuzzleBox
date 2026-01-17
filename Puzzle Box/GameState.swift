//
//  GameState.swift
//  Puzzle Box
//

import SwiftUI
import Combine

// MARK: - Game State

final class GameState: ObservableObject {
    // Published properties
    @Published var balls: [Ball] = []
    @Published var currentLayerIndex: Int = 0
    @Published var currentDifficulty: Int = 0
    @Published var isLevelComplete: Bool = false
    @Published var currentLevel: Level
    @Published var physicsReversed: Bool = false
    
    // Constants
    let ballRadius: CGFloat = 8
    var mazeSize: CGFloat
    
    // Dependencies
    private let motionManager: MotionInputProvider
    private let levelGenerator: LevelGenerating
    private let physicsEngine: PhysicsEngineProtocol
    private let hapticProvider: HapticFeedbackProvider
    
    // MARK: - Initialization
    
    init(
        screenSize: CGSize,
        motionManager: MotionInputProvider = MotionManager(),
        levelGenerator: LevelGenerating = LevelGenerator(),
        physicsEngine: PhysicsEngineProtocol = PhysicsEngine(),
        hapticProvider: HapticFeedbackProvider = HapticManager.shared
    ) {
        self.mazeSize = min(screenSize.width, screenSize.height) * 0.9
        self.motionManager = motionManager
        self.levelGenerator = levelGenerator
        self.physicsEngine = physicsEngine
        self.hapticProvider = hapticProvider
        self.currentLevel = levelGenerator.generateLevel(difficulty: 0, mazeSize: mazeSize)
        
        startLevel()
        motionManager.startUpdates()
    }
    
    // MARK: - Public Methods
    
    func updateMazeSize(_ size: CGSize) {
        mazeSize = min(size.width, size.height) * 0.9
    }
    
    var currentLayer: MazeLayer {
        currentLevel.layers[currentLayerIndex]
    }
    
    func startLevel() {
        currentLayerIndex = 0
        balls = currentLevel.layers[0].initialBalls
        isLevelComplete = false
        physicsReversed = false
    }
    
    func generateNewLevel() {
        currentDifficulty += 1
        currentLevel = levelGenerator.generateLevel(difficulty: currentDifficulty, mazeSize: mazeSize)
        startLevel()
    }
    
    func updatePhysics(deltaTime: Double) {
        let tilt = physicsReversed ?
            CGPoint(x: -motionManager.currentTilt.x, y: -motionManager.currentTilt.y) :
            motionManager.currentTilt
        
        physicsEngine.updateBalls(
            &balls,
            tilt: tilt,
            walls: currentLayer.walls,
            ballRadius: ballRadius,
            mazeSize: mazeSize,
            deltaTime: deltaTime,
            hapticProvider: hapticProvider
        )
        
        checkHoleCollisions()
        checkReverseWallCollisions()
    }
    
    // MARK: - Private Methods
    
    private func checkHoleCollisions() {
        var hasCompletedBall = false
        
        for i in balls.indices where !balls[i].isCompleted {
            for hole in currentLayer.holes {
                let dx = balls[i].position.x - hole.position.x
                let dy = balls[i].position.y - hole.position.y
                let distance = sqrt(dx * dx + dy * dy)
                
                if distance < hole.radius / 2 {
                    balls[i].isCompleted = true
                    hapticProvider.holeSuccess()
                    hasCompletedBall = true
                }
            }
        }
        
        if hasCompletedBall && balls.allSatisfy({ $0.isCompleted }) {
            advanceLayer()
        }
    }
    
    private func checkReverseWallCollisions() {
        for ball in balls where !ball.isCompleted {
            for wall in currentLayer.walls where wall.type == .reverse {
                let closestX = max(wall.rect.minX, min(ball.position.x, wall.rect.maxX))
                let closestY = max(wall.rect.minY, min(ball.position.y, wall.rect.maxY))
                
                let dx = ball.position.x - closestX
                let dy = ball.position.y - closestY
                let distance = sqrt(dx * dx + dy * dy)
                
                if distance < ballRadius {
                    physicsReversed.toggle()
                    hapticProvider.boundaryHit()
                    break
                }
            }
        }
    }
    
    private func advanceLayer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            if self.currentLayerIndex < self.currentLevel.layers.count - 1 {
                self.currentLayerIndex += 1
                self.physicsReversed = false
                
                let holePos = self.currentLevel.layers[self.currentLayerIndex - 1].holes.first?.position ?? .zero
                self.balls = self.balls.map { ball in
                    Ball(id: ball.id, position: holePos, velocity: .zero)
                }
            } else {
                self.isLevelComplete = true
            }
        }
    }
}
