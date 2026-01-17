//
//  LevelCompleteView.swift
//  Puzzle Box
//
//  Created by Luke Bresler on 2026/01/17.
//


//
//  LevelCompleteView.swift
//  Puzzle Box
//

import SwiftUI

// MARK: - Level Complete View

struct LevelCompleteView: View {
    let onNextLevel: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
            
            VStack(spacing: 20) {
                Text("🎉")
                    .font(.system(size: 60))
                
                Text("Level Complete!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                Button("Next Level") {
                    onNextLevel()
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