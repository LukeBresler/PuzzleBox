//
//  ContentView.swift
//  Puzzle Box
//
//  Created by Luke Bresler on 2026/01/15.
//

import SwiftUI
import CoreMotion
import Combine

// MARK: - Haptic Manager

class HapticManager {
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

// MARK: - Models

struct Ball: Identifiable {
    let id: Int
    var position: CGPoint
    var velocity: CGPoint
    var isCompleted: Bool = false
}

struct Wall {
    let rect: CGRect
}

struct Hole {
    let position: CGPoint
    let radius: CGFloat = 12
}

struct MazeLayer {
    let walls: [Wall]
    let holes: [Hole]
    var initialBalls: [Ball]
}

struct Level {
    let name: String
    let layers: [MazeLayer]
}

// MARK: - Level Generator

class LevelGenerator {
    static func generateLevel(difficulty: Int, mazeSize: CGFloat) -> Level {
        let numLayers = min(2 + difficulty / 2, 5)
        let numBalls = min(1 + difficulty / 3, 3)
        
        var layers: [MazeLayer] = []
        
        for layerIndex in 0..<numLayers {
            let isFirstLayer = layerIndex == 0
            let numWalls = 2 + difficulty + Int.random(in: 0...2)
            let numHoles = isFirstLayer ? numBalls : max(1, numBalls - layerIndex)
            
            var walls: [Wall] = []
            
            // Generate walls
            for _ in 0..<numWalls {
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
            
            // Generate holes in accessible areas
            var holes: [Hole] = []
            for _ in 0..<numHoles {
                var validHole = false
                var holePos = CGPoint.zero
                var attempts = 0
                
                while !validHole && attempts < 50 {
                    holePos = CGPoint(
                        x: CGFloat.random(in: 50...(mazeSize - 50)),
                        y: CGFloat.random(in: 50...(mazeSize - 50))
                    )
                    
                    // Check hole isn't too close to walls
                    validHole = true
                    for wall in walls {
                        let closestX = max(wall.rect.minX, min(holePos.x, wall.rect.maxX))
                        let closestY = max(wall.rect.minY, min(holePos.y, wall.rect.maxY))
                        let dist = hypot(holePos.x - closestX, holePos.y - closestY)
                        if dist < 30 {
                            validHole = false
                            break
                        }
                    }
                    
                    // Check not too close to other holes
                    for hole in holes {
                        if hypot(holePos.x - hole.position.x, holePos.y - hole.position.y) < 40 {
                            validHole = false
                            break
                        }
                    }
                    
                    attempts += 1
                }
                
                if validHole {
                    holes.append(Hole(position: holePos))
                }
            }
            
            // Ensure at least one hole
            if holes.isEmpty {
                holes.append(Hole(position: CGPoint(x: mazeSize * 0.8, y: mazeSize * 0.8)))
            }
            
            // Generate balls for first layer
            var balls: [Ball] = []
            if isFirstLayer {
                for i in 0..<numBalls {
                    let ballPos = CGPoint(
                        x: 30 + CGFloat(i * 40),
                        y: 30 + CGFloat(i * 30)
                    )
                    balls.append(Ball(id: i, position: ballPos, velocity: .zero))
                }
            }
            
            layers.append(MazeLayer(walls: walls, holes: holes, initialBalls: balls))
        }
        
        return Level(name: "Level \(difficulty + 1)", layers: layers)
    }
}

// MARK: - Game State

class GameState: ObservableObject {
    @Published var balls: [Ball] = []
    @Published var currentLayerIndex: Int = 0
    @Published var currentDifficulty: Int = 0
    @Published var isLevelComplete: Bool = false
    @Published var currentLevel: Level
    
    let motionManager = CMMotionManager()
    var tilt: CGPoint = .zero
    
    let ballRadius: CGFloat = 8
    var mazeSize: CGFloat
    
    init(screenSize: CGSize) {
        self.mazeSize = min(screenSize.width, screenSize.height) * 0.9
        self.currentLevel = LevelGenerator.generateLevel(difficulty: 0, mazeSize: mazeSize)
        startLevel()
        startMotionUpdates()
    }
    
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
    }
    
    func generateNewLevel() {
        currentDifficulty += 1
        currentLevel = LevelGenerator.generateLevel(difficulty: currentDifficulty, mazeSize: mazeSize)
        startLevel()
    }
    
    func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 1/60
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let motion = motion, let self = self else { return }
            
            let pitch = motion.attitude.pitch
            let roll = motion.attitude.roll
            
            self.tilt = CGPoint(
                x: CGFloat(roll) * 30,
                y: CGFloat(pitch) * 30
            )
        }
    }
    
    func updatePhysics(deltaTime: Double) {
        let gravity: CGFloat = 0.5
        let friction: CGFloat = 0.98
        let restitution: CGFloat = 0.7
        
        for i in balls.indices {
            if balls[i].isCompleted { continue }
            
            balls[i].velocity.x += tilt.x * gravity * deltaTime
            balls[i].velocity.y += tilt.y * gravity * deltaTime
            
            balls[i].velocity.x *= friction
            balls[i].velocity.y *= friction
            
            balls[i].position.x += balls[i].velocity.x * deltaTime
            balls[i].position.y += balls[i].velocity.y * deltaTime
            
            handleBoundaryCollision(at: i, restitution: restitution)
            handleWallCollisions(at: i, restitution: restitution)
            handleBallCollisions(at: i, restitution: restitution)
            checkHoleCollision(at: i)
        }
    }
    
    private func handleBoundaryCollision(at index: Int, restitution: CGFloat) {
        var didCollide = false
        
        if balls[index].position.x - ballRadius < 0 {
            balls[index].position.x = ballRadius
            balls[index].velocity.x = abs(balls[index].velocity.x) * restitution
            didCollide = true
        }
        if balls[index].position.x + ballRadius > mazeSize {
            balls[index].position.x = mazeSize - ballRadius
            balls[index].velocity.x = -abs(balls[index].velocity.x) * restitution
            didCollide = true
        }
        if balls[index].position.y - ballRadius < 0 {
            balls[index].position.y = ballRadius
            balls[index].velocity.y = abs(balls[index].velocity.y) * restitution
            didCollide = true
        }
        if balls[index].position.y + ballRadius > mazeSize {
            balls[index].position.y = mazeSize - ballRadius
            balls[index].velocity.y = -abs(balls[index].velocity.y) * restitution
            didCollide = true
        }
        
        if didCollide {
            HapticManager.shared.boundaryHit()
        }
    }
    
    private func handleWallCollisions(at index: Int, restitution: CGFloat) {
        for wall in currentLayer.walls {
            let closestX = max(wall.rect.minX, min(balls[index].position.x, wall.rect.maxX))
            let closestY = max(wall.rect.minY, min(balls[index].position.y, wall.rect.maxY))
            
            let dx = balls[index].position.x - closestX
            let dy = balls[index].position.y - closestY
            let distance = sqrt(dx * dx + dy * dy)
            
            if distance < ballRadius && distance > 0.001 {
                let overlap = ballRadius - distance
                let nx = dx / distance
                let ny = dy / distance
                
                let impactVelocity = sqrt(balls[index].velocity.x * balls[index].velocity.x +
                                         balls[index].velocity.y * balls[index].velocity.y)
                HapticManager.shared.wallHit(intensity: impactVelocity)
                
                balls[index].position.x += nx * (overlap + 0.1)
                balls[index].position.y += ny * (overlap + 0.1)
                
                let dotProduct = balls[index].velocity.x * nx + balls[index].velocity.y * ny
                balls[index].velocity.x = (balls[index].velocity.x - 2 * dotProduct * nx) * restitution
                balls[index].velocity.y = (balls[index].velocity.y - 2 * dotProduct * ny) * restitution
                
                balls[index].position.x = max(ballRadius, min(mazeSize - ballRadius, balls[index].position.x))
                balls[index].position.y = max(ballRadius, min(mazeSize - ballRadius, balls[index].position.y))
            }
        }
    }
    
    private func handleBallCollisions(at index: Int, restitution: CGFloat) {
        for j in balls.indices where j != index && !balls[j].isCompleted {
            let dx = balls[j].position.x - balls[index].position.x
            let dy = balls[j].position.y - balls[index].position.y
            let distance = sqrt(dx * dx + dy * dy)
            
            if distance < ballRadius * 2 {
                let overlap = ballRadius * 2 - distance
                let nx = dx / distance
                let ny = dy / distance
                
                balls[index].position.x -= nx * overlap / 2
                balls[index].position.y -= ny * overlap / 2
                
                let dvx = balls[j].velocity.x - balls[index].velocity.x
                let dvy = balls[j].velocity.y - balls[index].velocity.y
                let dotProduct = dvx * nx + dvy * ny
                
                balls[index].velocity.x += dotProduct * nx * restitution
                balls[index].velocity.y += dotProduct * ny * restitution
            }
        }
    }
    
    private func checkHoleCollision(at index: Int) {
        for hole in currentLayer.holes {
            let dx = balls[index].position.x - hole.position.x
            let dy = balls[index].position.y - hole.position.y
            let distance = sqrt(dx * dx + dy * dy)
            
            if distance < hole.radius / 2 {
                balls[index].isCompleted = true
                HapticManager.shared.holeSuccess()
                
                if balls.allSatisfy({ $0.isCompleted }) {
                    advanceLayer()
                }
            }
        }
    }
    
    private func advanceLayer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.currentLayerIndex < self.currentLevel.layers.count - 1 {
                self.currentLayerIndex += 1
                
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

// MARK: - Views

struct MazeView: View {
    let layer: MazeLayer
    let balls: [Ball]
    let ballRadius: CGFloat
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(white: 0.1))
            
            Path { path in
                for i in stride(from: 0, through: size, by: 40) {
                    path.move(to: CGPoint(x: i, y: 0))
                    path.addLine(to: CGPoint(x: i, y: size))
                    path.move(to: CGPoint(x: 0, y: i))
                    path.addLine(to: CGPoint(x: size, y: i))
                }
            }
            .stroke(Color(white: 0.15), lineWidth: 1)
            
            ForEach(layer.holes.indices, id: \.self) { index in
                Circle()
                    .fill(Color.black)
                    .frame(width: layer.holes[index].radius * 2, height: layer.holes[index].radius * 2)
                    .overlay(
                        Circle()
                            .stroke(Color(white: 0.3), lineWidth: 2)
                    )
                    .position(layer.holes[index].position)
            }
            
            ForEach(layer.walls.indices, id: \.self) { index in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.5), Color(white: 0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: layer.walls[index].rect.width, height: layer.walls[index].rect.height)
                    .position(
                        x: layer.walls[index].rect.midX,
                        y: layer.walls[index].rect.midY
                    )
            }
            
            ForEach(balls.filter { !$0.isCompleted }) { ball in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(white: 0.9), Color(white: 0.5)],
                            center: .init(x: 0.3, y: 0.3),
                            startRadius: 0,
                            endRadius: ballRadius
                        )
                    )
                    .frame(width: ballRadius * 2, height: ballRadius * 2)
                    .overlay(
                        Circle()
                            .stroke(Color(white: 0.4), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 2, y: 2)
                    .position(ball.position)
            }
        }
        .frame(width: size, height: size)
        .cornerRadius(12)
    }
}

struct ContentView: View {
    @StateObject private var gameState: GameState
    @State private var lastUpdate = Date()
    
    let timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
    
    init() {
        let screenSize = UIScreen.main.bounds.size
        _gameState = StateObject(wrappedValue: GameState(screenSize: screenSize))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(white: 0.05)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    VStack(spacing: 8) {
                        Text(gameState.currentLevel.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Layer \(gameState.currentLayerIndex + 1) of \(gameState.currentLevel.layers.count)")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    
                    Spacer()
                    
                    MazeView(
                        layer: gameState.currentLayer,
                        balls: gameState.balls,
                        ballRadius: gameState.ballRadius,
                        size: gameState.mazeSize
                    )
                    .overlay(
                        Group {
                            if gameState.isLevelComplete {
                                levelCompleteOverlay
                            }
                        }
                    )
                    
                    Spacer()
                    
                    Text("Tilt your device to guide the ball(s)")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .padding(.bottom, 20)
                }
            }
            .onAppear {
                gameState.updateMazeSize(geometry.size)
            }
            .onChange(of: geometry.size) { newSize in
                gameState.updateMazeSize(newSize)
            }
        }
        .onReceive(timer) { _ in
            let now = Date()
            let deltaTime = min(now.timeIntervalSince(lastUpdate) * 60, 2.0)
            lastUpdate = now
            
            if !gameState.isLevelComplete {
                gameState.updatePhysics(deltaTime: deltaTime)
            }
        }
    }
    
    var levelCompleteOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
            
            VStack(spacing: 20) {
                Text("🎉")
                    .font(.system(size: 60))
                
                Text("Level Complete!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                Button("Next Level") {
                    gameState.generateNewLevel()
                }
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
        .cornerRadius(12)
    }
}

#Preview {
    ContentView()
}
