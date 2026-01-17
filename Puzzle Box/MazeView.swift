//
//  MazeView.swift
//  Puzzle Box
//

import SwiftUI

// MARK: - Maze View

struct MazeView: View {
    let layer: MazeLayer
    let balls: [Ball]
    let ballRadius: CGFloat
    let size: CGFloat
    
    var body: some View {
        ZStack {
            backgroundLayer
            gridLayer
            holesLayer
            wallsLayer
            ballsLayer
        }
        .frame(width: size, height: size)
        .cornerRadius(12)
    }
    
    // MARK: - View Components
    
    private var backgroundLayer: some View {
        Rectangle()
            .fill(Color(white: 0.1))
    }
    
    private var gridLayer: some View {
        Path { path in
            for i in stride(from: 0, through: size, by: 40) {
                path.move(to: CGPoint(x: i, y: 0))
                path.addLine(to: CGPoint(x: i, y: size))
                path.move(to: CGPoint(x: 0, y: i))
                path.addLine(to: CGPoint(x: size, y: i))
            }
        }
        .stroke(Color(white: 0.15), lineWidth: 1)
    }
    
    private var holesLayer: some View {
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
    }
    
    private var wallsLayer: some View {
        ForEach(layer.walls.indices, id: \.self) { index in
            let wall = layer.walls[index]
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: {
                            switch wall.type {
                            case .reverse:
                                return [Color.orange, Color.orange.opacity(0.8)]
                            case .magnet:
                                return [Color.blue, Color.blue.opacity(0.8)]
                            case .normal:
                                return [Color(white: 0.5), Color(white: 0.4)]
                            }
                        }(),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: wall.rect.width, height: wall.rect.height)
                .overlay(
                    Group {
                        if wall.type == .reverse {
                            Rectangle()
                                .strokeBorder(Color.orange.opacity(0.6), lineWidth: 2)
                        } else if wall.type == .magnet {
                            ZStack {
                                Rectangle()
                                    .strokeBorder(Color.blue.opacity(0.6), lineWidth: 2)
                                
                                // Add magnetic field effect
                                Circle()
                                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                    .frame(width: 100, height: 100)
                                
                                Circle()
                                    .stroke(Color.blue.opacity(0.15), lineWidth: 1)
                                    .frame(width: 150, height: 150)
                            }
                        }
                    }
                )
                .position(
                    x: wall.rect.midX,
                    y: wall.rect.midY
                )
        }
    }
    
    private var ballsLayer: some View {
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
}
