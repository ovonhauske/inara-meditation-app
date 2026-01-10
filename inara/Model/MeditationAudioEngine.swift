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

extension MeditationAudioEngine: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            print("[AudioEngine] Delegate called on Main Thread: \(Thread.isMainThread)")
            if player == self.bellPlayer && flag {
                print("[AudioEngine] Bell finished. Starting meditation.")
                self.hasPlayedBell = true
                self.bellPlayer?.stop()
                self.bellPlayer?.prepareToPlay() // Reset for next time
                
                // Start the main content
                self.resumeAudio()
                self.startTimer()
                self.updateNowPlayingPlayback(isPlaying: true)
            }
        }
    }
}

final class MeditationAudioEngine: NSObject { // Inherit NSObject for Delegate
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
    private var bellPlayer: AVAudioPlayer?
    
    private var hasPlayedBell: Bool = false

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
        bellPlayer?.stop()
        
        hasPlayedBell = false // Reset bell state on stop
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        teardownRemoteCommands()
    }

    func play() {
        state.isPlaying = true
        
        // Logic: Try to play bell first if it hasn't played
        if !hasPlayedBell, let bell = bellPlayer {
            print("[AudioEngine] Playing Bell...")
            bell.play()
            updateNowPlayingPlayback(isPlaying: true)
        } else {
            // Bell already played or doesn't exist, play main content
            resumeAudio()
            startTimer()
            updateNowPlayingPlayback(isPlaying: true)
        }
    }

    func pause() {
        state.isPlaying = false
        stopTimer()
        pauseAudio() // This now also needs to pause bell
        updateNowPlayingPlayback(isPlaying: false)
    }

    func seek(to time: TimeInterval) {
        // If we seek to 0, we reset the bell so it plays again on start.
        // If we seek > 0, we assume the user skipped the intro.
        if time < 1.0 {
            hasPlayedBell = false
        } else {
            hasPlayedBell = true
            bellPlayer?.stop()
        }
        
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
        // Bell usually distinct, keep full or match narration? Let's match narration.
        bellPlayer?.volume = Float(narrationVolume)
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
        setupBell()
        setVolumes(soundscape: soundscapeVolume, narration: narrationVolume)
        setupInterruptionHandling()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error setting up audio session: \(error)")
        }
    }
    
    private func setupInterruptionHandling() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleInterruption),
                                               name: AVAudioSession.interruptionNotification,
                                               object: nil)
    }
    
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        
        switch type {
        case .began:
            if state.isPlaying {
                pause() // Should ideally allow resume. Logic to auto-resume would go here.
            }
        case .ended:
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                 let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                 if options.contains(.shouldResume) {
                     // Optionally resume playback if it was playing before
                 }
            }
        @unknown default: break
        }
    }

    private func pauseAudio() {
        // Bell Logic
        if let bell = bellPlayer, bell.isPlaying {
            bell.pause()
            // We return here? No, let's pause everything just in case something got out of sync
        }
        
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
        print("[AudioEngine] resumeAudio. ScapeTime: \(soundscapeTimestamp), ClosingStart: \(closingNarrationStartTime)")
        
        // Safety: Re-apply volumes ensure not muted
        setVolumes(soundscape: soundscapeVolume, narration: narrationVolume)
        
        if let scape = soundscapePlayer {
            scape.currentTime = soundscapeTimestamp
            scape.play()
        }

        // narrations follow your same rules
        if let opening = openingNarrationPlayer,
           opening.duration > 0 {
            
            if soundscapeTimestamp < closingNarrationStartTime {
                print("[AudioEngine] Playing Opening Narration")
                opening.currentTime = narrationTimestamp
                opening.play()
            } else {
                print("[AudioEngine] Skipping Opening: Past closing start")
            }
        } else {
            print("[AudioEngine] No opening player or duration 0")
        }

        if let closing = closingNarrationPlayer,
           closing.duration > 0,
           soundscapeTimestamp >= closingNarrationStartTime {
            print("[AudioEngine] Playing Closing Narration")
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

    // MARK: - Optimized Resource Discovery
    // Dropped extensive loops for direct subpath checking. This is much faster.

    private func categoryToken(from path: String) -> String {
        let comps = path.split(separator: "/").map(String.init)
        return comps.last ?? path
    }
    
    /// Finds a resource by checking a specific set of likely paths instead of scanning the entire bundle.
    private func findResource(names: [String], extensions: [String], subdirectory: String? = nil) -> URL? {
        print("[AudioEngine] Searching in subdir: \(subdirectory ?? "root")")
        for name in names {
            for ext in extensions {
                if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: subdirectory) {
                    print("[AudioEngine] FOUND: \(name).\(ext)")
                    return url
                } else {
                     // print("[AudioEngine] Not found: \(name).\(ext)") // Commented out to avoid spam, uncomment if needed
                }
            }
        }
        return nil
    }

    private func setupSoundscape() {
        let token = categoryToken(from: folder)
        let candidates = [
            "\(token)_soundscape", "soundscape_\(token)", "soundscape", "Soundscape"
        ]
        
        print("[AudioEngine] Setup Soundscape. Token: \(token), Folder: \(folder)")
        
        // Optimize: Check specific folder first, then generic 'audio'
        if let url = findResource(names: candidates, extensions: ["mp3", "m4a"], subdirectory: folder) ??
                     findResource(names: candidates, extensions: ["mp3", "m4a"], subdirectory: "audio/\(token)") ??
                     findResource(names: candidates, extensions: ["mp3", "m4a"]) {
            loadSoundscape(from: url)
        } else {
            print("[AudioEngine] Soundscape not found for token: \(token)")
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
                
                // VALIDATION FIX: Default closing start to end of track.
                // If closing narration exists, it will overwrite this with (duration - closingDuration).
                // If it doesn't exist, this ensures 'opening' can still play (0 < duration).
                closingNarrationStartTime = duration
                
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
        let candidates = [
            "\(token)_opening", "opening_\(token)", "opening", "Opening",
            "\(token)_intro", "intro_\(token)", "intro"
        ]
        
        print("[AudioEngine] Setup Opening. Token: \(token), Candidates: \(candidates)")
        
        if let url = findResource(names: candidates, extensions: ["mp3", "m4a"], subdirectory: folder) ??
                     findResource(names: candidates, extensions: ["mp3", "m4a"], subdirectory: "audio/\(token)") ??
                     findResource(names: candidates, extensions: ["mp3", "m4a"]) {
            do {
                openingNarrationPlayer = try AVAudioPlayer(contentsOf: url)
                openingNarrationPlayer?.prepareToPlay()
                print("[AudioEngine] Loaded Opening: \(url.lastPathComponent)")
            } catch {
                print("Error loading opening narration: \(error)")
            }
        } else {
            print("[AudioEngine] Opening narration NOT found for token: \(token)")
        }
    }

    private func setupClosingNarration() {
        let token = categoryToken(from: folder)
        let candidates = [
             "\(token)_closing", "closing_\(token)", "closing", "Closing",
             "\(token)_outro", "outro_\(token)", "outro"
        ]
        
        if let url = findResource(names: candidates, extensions: ["mp3", "m4a"], subdirectory: folder) ??
                     findResource(names: candidates, extensions: ["mp3", "m4a"], subdirectory: "audio/\(token)") ??
                     findResource(names: candidates, extensions: ["mp3", "m4a"]) {
            do {
                closingNarrationPlayer = try AVAudioPlayer(contentsOf: url)
                closingNarrationPlayer?.prepareToPlay()
                if let duration = closingNarrationPlayer?.duration {
                    closingNarrationDuration = duration
                    if let scapeDuration = soundscapePlayer?.duration {
                        closingNarrationStartTime = scapeDuration - duration
                    }
                    print("[AudioEngine] Loaded Closing: \(url.lastPathComponent), StartTime: \(closingNarrationStartTime)")
                }
            } catch {
                print("Error loading closing narration: \(error)")
            }
        } else {
            print("[AudioEngine] Closing narration NOT found for token: \(token)")
        }
    }
    
    private func setupBell() {
        // Bell is located at audio/player/start.mp3
        if let url = findResource(names: ["start"], extensions: ["mp3", "m4a"], subdirectory: "audio/player") {
            do {
                bellPlayer = try AVAudioPlayer(contentsOf: url)
                bellPlayer?.delegate = self // IMPORTANT: Set delegate to detect finish
                bellPlayer?.prepareToPlay()
            } catch {
                print("Error loading bell: \(error)")
            }
        } else {
             // Try fallback if user moved it
             if let url = findResource(names: ["start"], extensions: ["mp3", "m4a"]) {
                 do {
                     bellPlayer = try AVAudioPlayer(contentsOf: url)
                     bellPlayer?.delegate = self
                     bellPlayer?.prepareToPlay()
                 } catch {
                     print("Error loading bell (fallback): \(error)")
                 }
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
