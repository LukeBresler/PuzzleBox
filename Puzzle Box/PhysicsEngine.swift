//
//  PhysicsConfiguration.swift
//  Puzzle Box
//
//  Created by Luke Bresler on 2026/01/17.
//


//
//  PhysicsEngine.swift
//  Puzzle Box
//

import CoreGraphics

// MARK: - Physics Configuration

struct PhysicsConfiguration {
    let gravity: CGFloat = 0.5
    let friction: CGFloat = 0.98
    let restitution: CGFloat = 0.7
}

// MARK: - Physics Engine Protocol

protocol PhysicsEngineProtocol {
    func updateBalls(
        _ balls: inout [Ball],
        tilt: CGPoint,
        walls: [Wall],
        ballRadius: CGFloat,
        mazeSize: CGFloat,
        deltaTime: Double,
        hapticProvider: HapticFeedbackProvider
    )
}

// MARK: - Physics Engine

final class PhysicsEngine: PhysicsEngineProtocol {
    private let config = PhysicsConfiguration()
    
    func updateBalls(
        _ balls: inout [Ball],
        tilt: CGPoint,
        walls: [Wall],
        ballRadius: CGFloat,
        mazeSize: CGFloat,
        deltaTime: Double,
        hapticProvider: HapticFeedbackProvider
    ) {
        for i in balls.indices {
            if balls[i].isCompleted { continue }
            
            applyGravity(to: &balls[i], tilt: tilt, deltaTime: deltaTime)
            applyFriction(to: &balls[i])
            updatePosition(of: &balls[i], deltaTime: deltaTime)
            
            handleBoundaryCollision(
                ball: &balls[i],
                ballRadius: ballRadius,
                mazeSize: mazeSize,
                hapticProvider: hapticProvider
            )
            
            handleWallCollisions(
                ball: &balls[i],
                walls: walls,
                ballRadius: ballRadius,
                mazeSize: mazeSize,
                hapticProvider: hapticProvider
            )
            
            handleBallCollisions(
                at: i,
                balls: &balls,
                ballRadius: ballRadius
            )
        }
    }
    
    // MARK: - Private Methods
    
    private func applyGravity(to ball: inout Ball, tilt: CGPoint, deltaTime: Double) {
        ball.velocity.x += tilt.x * config.gravity * deltaTime
        ball.velocity.y += tilt.y * config.gravity * deltaTime
    }
    
    private func applyFriction(to ball: inout Ball) {
        ball.velocity.x *= config.friction
        ball.velocity.y *= config.friction
    }
    
    private func updatePosition(of ball: inout Ball, deltaTime: Double) {
        ball.position.x += ball.velocity.x * deltaTime
        ball.position.y += ball.velocity.y * deltaTime
    }
    
    private func handleBoundaryCollision(
        ball: inout Ball,
        ballRadius: CGFloat,
        mazeSize: CGFloat,
        hapticProvider: HapticFeedbackProvider
    ) {
        var didCollide = false
        
        if ball.position.x - ballRadius < 0 {
            ball.position.x = ballRadius
            ball.velocity.x = abs(ball.velocity.x) * config.restitution
            didCollide = true
        }
        if ball.position.x + ballRadius > mazeSize {
            ball.position.x = mazeSize - ballRadius
            ball.velocity.x = -abs(ball.velocity.x) * config.restitution
            didCollide = true
        }
        if ball.position.y - ballRadius < 0 {
            ball.position.y = ballRadius
            ball.velocity.y = abs(ball.velocity.y) * config.restitution
            didCollide = true
        }
        if ball.position.y + ballRadius > mazeSize {
            ball.position.y = mazeSize - ballRadius
            ball.velocity.y = -abs(ball.velocity.y) * config.restitution
            didCollide = true
        }
        
        if didCollide {
            hapticProvider.boundaryHit()
        }
    }
    
    private func handleWallCollisions(
        ball: inout Ball,
        walls: [Wall],
        ballRadius: CGFloat,
        mazeSize: CGFloat,
        hapticProvider: HapticFeedbackProvider
    ) {
        for wall in walls {
            let closestX = max(wall.rect.minX, min(ball.position.x, wall.rect.maxX))
            let closestY = max(wall.rect.minY, min(ball.position.y, wall.rect.maxY))
            
            let dx = ball.position.x - closestX
            let dy = ball.position.y - closestY
            let distance = sqrt(dx * dx + dy * dy)
            
            if distance < ballRadius && distance > 0.001 {
                let overlap = ballRadius - distance
                let nx = dx / distance
                let ny = dy / distance
                
                let impactVelocity = sqrt(ball.velocity.x * ball.velocity.x +
                                         ball.velocity.y * ball.velocity.y)
                hapticProvider.wallHit(intensity: impactVelocity)
                
                ball.position.x += nx * (overlap + 0.1)
                ball.position.y += ny * (overlap + 0.1)
                
                let dotProduct = ball.velocity.x * nx + ball.velocity.y * ny
                ball.velocity.x = (ball.velocity.x - 2 * dotProduct * nx) * config.restitution
                ball.velocity.y = (ball.velocity.y - 2 * dotProduct * ny) * config.restitution
                
                ball.position.x = max(ballRadius, min(mazeSize - ballRadius, ball.position.x))
                ball.position.y = max(ballRadius, min(mazeSize - ballRadius, ball.position.y))
            }
        }
    }
    
    private func handleBallCollisions(
        at index: Int,
        balls: inout [Ball],
        ballRadius: CGFloat
    ) {
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
                
                balls[index].velocity.x += dotProduct * nx * config.restitution
                balls[index].velocity.y += dotProduct * ny * config.restitution
            }
        }
    }
}