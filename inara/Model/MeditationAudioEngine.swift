//
//  MeditationAudioEngine.swift
//  inara
//
//  Created by Oscar von Hauske on 12/28/25.
//

import Foundation

import Foundation
import AVFoundation
import MediaPlayer
import UIKit

final class MeditationAudioEngine {
    struct State {
        var isPlaying: Bool = false
        var timeRemaining: Int = 0
        var totalDuration: Int = 0
        var progress: Double = 0
    }

    var onState: ((State) -> Void)?

    private var title: String = ""
    private var folder: String = ""

    private var state = State() { didSet { onState?(state) } }

    private var timer: Timer?

    private var soundscapePlayer: AVAudioPlayer?
    private var openingNarrationPlayer: AVAudioPlayer?
    private var closingNarrationPlayer: AVAudioPlayer?

    private var soundscapeVolume: Double = 0.5
    private var narrationVolume: Double = 0.5

    private var soundscapeTimestamp: TimeInterval = 0
    private var narrationTimestamp: TimeInterval = 0
    private var closingNarrationStartTime: TimeInterval = 0
    private var closingNarrationDuration: TimeInterval = 0

    func configure(title: String, folder: String) {
        self.title = title
        self.folder = folder
    }

    func start() {
        setupAudioSession()
        setupAudio()
        setupRemoteCommands()
        configureNowPlayingInfo()
    }

    func stop() {
        stopTimer()
        soundscapePlayer?.stop()
        openingNarrationPlayer?.stop()
        closingNarrationPlayer?.stop()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        teardownRemoteCommands()
    }

    func play() {
        state.isPlaying = true
        resumeAudio()
        startTimer()
        updateNowPlayingPlayback(isPlaying: true)
    }

    func pause() {
        state.isPlaying = false
        stopTimer()
        pauseAudio()
        updateNowPlayingPlayback(isPlaying: false)
    }

    func seek(to time: TimeInterval) {
        seekInternal(to: time, autoPlay: state.isPlaying)
        publishTimeFrom(time: time)
        updateNowPlayingElapsed()
    }

    /// Optional: if you want live preview while scrubbing
    func scrubPreview(to time: TimeInterval) {
        seekInternal(to: time, autoPlay: false) // don’t fight audio while finger is down
        publishTimeFrom(time: time)
    }

    func setVolumes(soundscape: Double, narration: Double) {
        soundscapeVolume = soundscape
        narrationVolume = narration
        soundscapePlayer?.volume = Float(soundscapeVolume)
        openingNarrationPlayer?.volume = Float(narrationVolume)
        closingNarrationPlayer?.volume = Float(narrationVolume)
    }

    // MARK: - Timer / state publishing

    private func startTimer() {
        guard state.isPlaying, timer == nil else { return }

        let current = Int(soundscapePlayer?.currentTime ?? soundscapeTimestamp)
        state.timeRemaining = max(0, state.totalDuration - current)

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.state.timeRemaining > 0 {
                self.state.timeRemaining -= 1
                self.updateProgressFromRemaining()
                self.updateNowPlayingElapsed()

                let elapsed = Double(self.state.totalDuration - self.state.timeRemaining)
                if elapsed >= self.closingNarrationStartTime,
                   self.closingNarrationPlayer?.isPlaying == false {
                    self.playClosingNarration()
                }
            } else {
                self.pause() // stops timer + audio + now playing rate
                self.seek(to: 0)
            }
        }
    }

    private func stopTimer() { timer?.invalidate(); timer = nil }

    private func updateProgressFromRemaining() {
        guard state.totalDuration > 0 else { return }
        let elapsed = state.totalDuration - state.timeRemaining
        state.progress = Double(elapsed) / Double(state.totalDuration)
    }

    private func publishTimeFrom(time: TimeInterval) {
        state.timeRemaining = max(0, state.totalDuration - Int(time))
        state.progress = state.totalDuration > 0 ? (time / Double(state.totalDuration)) : 0
    }

    // MARK: - Audio setup

    private func setupAudio() {
        setupSoundscape()
        setupOpeningNarration()
        setupClosingNarration()
        setVolumes(soundscape: soundscapeVolume, narration: narrationVolume)
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error setting up audio session: \(error)")
        }
    }

    private func pauseAudio() {
        if let scape = soundscapePlayer {
            soundscapeTimestamp = scape.currentTime
            scape.pause()
        }
        if let opening = openingNarrationPlayer, opening.isPlaying {
            narrationTimestamp = opening.currentTime
            opening.pause()
        }
        if let closing = closingNarrationPlayer, closing.isPlaying {
            let remaining = closing.duration - closing.currentTime
            narrationTimestamp = closingNarrationDuration - remaining
            closing.pause()
        }
    }

    private func resumeAudio() {
        if let scape = soundscapePlayer {
            scape.currentTime = soundscapeTimestamp
            scape.play()
        }

        // narrations follow your same rules
        if let opening = openingNarrationPlayer,
           opening.duration > 0,
           soundscapeTimestamp < closingNarrationStartTime {
            opening.currentTime = narrationTimestamp
            opening.play()
        }

        if let closing = closingNarrationPlayer,
           closing.duration > 0,
           soundscapeTimestamp >= closingNarrationStartTime {
            closing.currentTime = narrationTimestamp
            closing.play()
        }
    }

    private func seekInternal(to time: TimeInterval, autoPlay: Bool) {
        if let scape = soundscapePlayer { scape.currentTime = time }
        openingNarrationPlayer?.stop()
        closingNarrationPlayer?.stop()

        // opening
        if let opening = openingNarrationPlayer, time < opening.duration {
            opening.currentTime = time
            if autoPlay { opening.play() }
            narrationTimestamp = time
        } else if time >= closingNarrationStartTime {
            // closing
            let narrationTime = max(0, time - closingNarrationStartTime)
            if let closing = closingNarrationPlayer {
                closing.currentTime = narrationTime
                if autoPlay { closing.play() }
            }
            narrationTimestamp = narrationTime
        } else {
            narrationTimestamp = 0
        }

        soundscapeTimestamp = time
    }

    // MARK: - Resource discovery (copy your helpers)

    private func categoryToken(from path: String) -> String {
        let comps = path.split(separator: "/").map(String.init)
        return comps.last ?? path
    }

    private func findResource(namedAnyOf names: [String], extensions exts: [String], inAnyOf subdirs: [String]) -> URL? {
        for dir in subdirs {
            let sub: String? = dir.isEmpty ? nil : dir
            for name in names {
                for ext in exts {
                    if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: sub) {
                        return url
                    }
                }
            }
        }
        return nil
    }

    private func findResource(containing tokens: [String], inAnyOf subdirs: [String]) -> URL? {
        let exts = ["mp3", "m4a", "wav", "aac"]
        for dir in subdirs {
            let sub: String? = dir.isEmpty ? nil : dir
            for ext in exts {
                if let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: sub) {
                    if let match = urls.first(where: { url in
                        let name = url.lastPathComponent.lowercased()
                        return tokens.contains(where: { token in name.contains(token.lowercased()) })
                    }) { return match }
                }
            }
        }
        return nil
    }

    private func setupSoundscape() {
        let token = categoryToken(from: folder)
        let baseNames = ["soundscape", "Soundscape", "SOUNDSCAPE"]
        let tokenNames = baseNames.flatMap { ["\(token)_\($0)", "\($0)_\(token)"] }
        let candidates = tokenNames + baseNames
        let exts = ["mp3", "m4a", "wav", "aac"]
        let dirs = [folder, "audio/\(token)", "audio", token, ""]
        if let url = findResource(namedAnyOf: candidates, extensions: exts, inAnyOf: dirs)
            ?? findResource(containing: ["soundscape"], inAnyOf: dirs) {
            loadSoundscape(from: url)
        } else {
            print("Soundscape not found token=\(token) in \(dirs)")
        }
    }

    private func loadSoundscape(from url: URL) {
        do {
            soundscapePlayer = try AVAudioPlayer(contentsOf: url)
            soundscapePlayer?.numberOfLoops = -1
            soundscapePlayer?.prepareToPlay()

            if let duration = soundscapePlayer?.duration {
                state.totalDuration = Int(duration)
                state.timeRemaining = state.totalDuration
                if closingNarrationDuration > 0 {
                    closingNarrationStartTime = duration - closingNarrationDuration
                }
            }
        } catch {
            print("Error loading soundscape: \(error)")
        }
    }

    private func setupOpeningNarration() {
        let token = categoryToken(from: folder)
        let baseNames = ["opening", "Opening", "OPENING", "intro", "Intro", "INTRO"]
        let tokenNames = baseNames.flatMap { ["\(token)_\($0)", "\($0)_\(token)"] }
        let candidates = tokenNames + baseNames
        let exts = ["mp3", "m4a", "wav", "aac"]
        let dirs = [folder, "audio/\(token)", "audio", token, ""]
        if let url = findResource(namedAnyOf: candidates, extensions: exts, inAnyOf: dirs)
            ?? findResource(containing: ["opening", "intro"], inAnyOf: dirs) {
            do {
                openingNarrationPlayer = try AVAudioPlayer(contentsOf: url)
                openingNarrationPlayer?.prepareToPlay()
            } catch {
                print("Error loading opening narration: \(error)")
            }
        }
    }

    private func setupClosingNarration() {
        let token = categoryToken(from: folder)
        let baseNames = ["closing", "Closing", "CLOSING", "outro", "Outro", "OUTRO", "end", "End", "END"]
        let tokenNames = baseNames.flatMap { ["\(token)_\($0)", "\($0)_\(token)"] }
        let candidates = tokenNames + baseNames
        let exts = ["mp3", "m4a", "wav", "aac"]
        let dirs = [folder, "audio/\(token)", "audio", token, ""]
        if let url = findResource(namedAnyOf: candidates, extensions: exts, inAnyOf: dirs)
            ?? findResource(containing: ["closing", "outro", "end"], inAnyOf: dirs) {
            do {
                closingNarrationPlayer = try AVAudioPlayer(contentsOf: url)
                closingNarrationPlayer?.prepareToPlay()
                if let duration = closingNarrationPlayer?.duration {
                    closingNarrationDuration = duration
                    if let scapeDuration = soundscapePlayer?.duration {
                        closingNarrationStartTime = scapeDuration - duration
                    }
                }
            } catch {
                print("Error loading closing narration: \(error)")
            }
        }
    }

    private func playClosingNarration() {
        guard let player = closingNarrationPlayer, player.duration > 0 else { return }
        let baseTime = soundscapePlayer?.currentTime ?? soundscapeTimestamp
        let relative = max(0, baseTime - closingNarrationStartTime)
        player.currentTime = min(relative, player.duration)
        player.play()
    }

    // MARK: - Now Playing / Remote Commands (copy your existing)

    private func configureNowPlayingInfo() {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: "Inara",
            MPNowPlayingInfoPropertyPlaybackRate: state.isPlaying ? 1.0 : 0.0,
            MPMediaItemPropertyPlaybackDuration: Double(state.totalDuration),
            MPNowPlayingInfoPropertyElapsedPlaybackTime: Double(state.totalDuration - state.timeRemaining)
        ]
        if let image = UIImage(named: "logo") {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func updateNowPlayingPlayback(isPlaying: Bool) {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = Double(state.totalDuration - state.timeRemaining)
        info[MPMediaItemPropertyPlaybackDuration] = Double(state.totalDuration)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func updateNowPlayingElapsed() {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = Double(state.totalDuration - state.timeRemaining)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func setupRemoteCommands() {
        let cc = MPRemoteCommandCenter.shared()
        cc.playCommand.isEnabled = true
        cc.pauseCommand.isEnabled = true
        cc.togglePlayPauseCommand.isEnabled = true

        cc.playCommand.addTarget { [weak self] _ in self?.play(); return .success }
        cc.pauseCommand.addTarget { [weak self] _ in self?.pause(); return .success }
        cc.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.state.isPlaying ? self.pause() : self.play()
            return .success
        }
    }

    private func teardownRemoteCommands() {
        let cc = MPRemoteCommandCenter.shared()
        cc.playCommand.removeTarget(nil)
        cc.pauseCommand.removeTarget(nil)
        cc.togglePlayPauseCommand.removeTarget(nil)
    }
}
