//
//  MeditationPlayerViewModel.swift
//  inara
//
//  Created by Oscar von Hauske on 12/28/25.
//

import Foundation
import SwiftUI

@MainActor
final class MeditationPlayerViewModel: ObservableObject {
    // Inputs
    let title: String
    let folder: String

    // UI-facing state
    @Published var isPlaying = false
    @Published var timeRemaining = 0
    @Published var totalDuration = 0
    @Published var progress: Double = 0.0
    @Published var isScrubbing = false
    @Published var showingBottomSheet = false

    @Published var soundscapeVolume: Double = 0.5
    @Published var narrationVolume: Double = 0.5

    private let engine: MeditationAudioEngine

    init(title: String, folder: String, engine: MeditationAudioEngine = .init()) {
        self.title = title
        self.folder = folder
        self.engine = engine

        // Bridge engine → UI
        engine.onState = { [weak self] state in
            guard let self else { return }
            self.isPlaying = state.isPlaying
            self.timeRemaining = state.timeRemaining
            self.totalDuration = state.totalDuration
            self.progress = state.progress
        }
    }

    var hasStarted: Bool { isPlaying || progress > 0 }

    func onAppear() {
        resetProgress()
        engine.configure(title: title, folder: folder)
        engine.setVolumes(soundscape: soundscapeVolume, narration: narrationVolume)
        engine.start() // sets up audio session, loads resources, sets remote commands, now playing
    }

    func onDisappear() {
        engine.stop()
    }

    func togglePlayPause() {
        if isPlaying { 
            engine.pause() 
        } else { 
            engine.play() 
            // Track last meditation session
            Task {
                try? await ProfileService.updateLastMeditationDate()
            }
        }
    }

    func updateVolumes() {
        engine.setVolumes(soundscape: soundscapeVolume, narration: narrationVolume)
    }

    func resetProgress() {
        progress = 0
        timeRemaining = totalDuration
        isScrubbing = false
        engine.seek(to: 0)
    }

    // Scrub from your polar gesture math
    func scrubChanged(location: CGPoint, center: CGPoint, radius: CGFloat) {
        guard hasStarted else { return }
        isScrubbing = true
        let time = scrubbedTime(from: location, center: center, total: totalDuration)
        engine.scrubPreview(to: time) // optional: can just call seek(to:)
    }

    func scrubEnded(location: CGPoint, center: CGPoint) {
        guard hasStarted else { return }
        isScrubbing = false
        let time = scrubbedTime(from: location, center: center, total: totalDuration)
        engine.seek(to: time)
        if !isPlaying { engine.play() } // matches your current behavior
    }

    private func scrubbedTime(from location: CGPoint, center: CGPoint, total: Int) -> TimeInterval {
        guard total > 0 else { return 0 }
        let offset = CGPoint(x: location.x - center.x, y: location.y - center.y)
        var angle = atan2(offset.y, offset.x)
        if angle < 0 { angle += 2 * .pi }
        let normalized = (angle + .pi/2).truncatingRemainder(dividingBy: 2 * .pi)
        let pct = normalized / (2 * .pi)
        return TimeInterval(Double(total) * pct)
    }
}
