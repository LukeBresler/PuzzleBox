//
//  ContentView.swift
//  Puzzle Box
//
//  Created by Luke Bresler on 2026/01/15.
//

import SwiftUI
import Combine

// MARK: - Content View

struct ContentView: View {
    @StateObject private var gameState: GameState
    @State private var lastUpdate = Date()
    
    private let timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
    
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
                    headerView
                    
                    Spacer()
                    
                    mazeView
                    
                    Spacer()
                    
                    instructionsView
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
            updateGame()
        }
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text(gameState.currentLevel.name)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                Text("Layer \(gameState.currentLayerIndex + 1) of \(gameState.currentLevel.layers.count)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                if gameState.physicsReversed {
                    Text("🔄 REVERSED")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 10)
    }
    
    private var mazeView: some View {
        MazeView(
            layer: gameState.currentLayer,
            balls: gameState.balls,
            ballRadius: gameState.ballRadius,
            size: gameState.mazeSize
        )
        .overlay(
            Group {
                if gameState.isLevelComplete {
                    LevelCompleteView {
                        gameState.generateNewLevel()
                    }
                }
            }
        )
    }
    
    private var instructionsView: some View {
        Text("Tilt your device to guide the ball(s)")
            .font(.system(size: 12))
            .foregroundColor(.gray)
            .padding(.bottom, 20)
    }
    
    // MARK: - Private Methods
    
    private func updateGame() {
        let now = Date()
        let deltaTime = min(now.timeIntervalSince(lastUpdate) * 60, 2.0)
        lastUpdate = now
        
        if !gameState.isLevelComplete {
            gameState.updatePhysics(deltaTime: deltaTime)
        }
    }
}

#Preview {
    ContentView()
}
