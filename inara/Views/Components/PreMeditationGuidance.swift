//
//  TextMeditationPrep.swift
//  inara
//
//  Created by Oscar von Hauske on 1/5/26.
//

import SwiftUI

struct PreMeditationGuidance: View {
    // The sequence of gentle instructions
    let instructions = [
        "Find a posture that feels steady.",
        "Headphones help you go deeper.",
        "Soften your gaze.",
        "Tap start when ready."
    ]
    
    @State private var index = 0
    @State private var opacity: Double = 0
    @State private var hasFinished = false
    
    var shouldLoop: Bool = false
    
    // Callback to tell the parent view to start the player
    var onComplete: () -> Void = {}
    
    var body: some View {
        ZStack {
            if !hasFinished || shouldLoop {
                Text(instructions[index])
                    .font(.body) // Readable but not shouting
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(AppColors.tulum)
                    .padding()
                    .opacity(opacity)
                    .onAppear {
                        cycleInstructions()
                    }
            }
        }
    }
    
    func cycleInstructions() {
        // 1. Fade In
        withAnimation(.easeInOut(duration: 2.0)) {
            opacity = 1.0
        }
        
        // 2. Wait (Read time), then Fade Out
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            withAnimation(.easeInOut(duration: 2.0)) {
                opacity = 0
            }
        }
        
        // 3. Advance to next instruction (with optional looping)
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.5) {
            if index < instructions.count - 1 {
                index += 1
                cycleInstructions() // Recursive call for next slide
            } else {
                if shouldLoop {
                    index = 0
                    hasFinished = false
                    cycleInstructions()
                } else {
                    hasFinished = true
                    onComplete() // Trigger the actual meditation player
                }
            }
        }
    }
}





#Preview {
    ZStack{
        AppColors.surface.ignoresSafeArea()
        PreMeditationGuidance(shouldLoop: true, onComplete: {})

    }
    
}

