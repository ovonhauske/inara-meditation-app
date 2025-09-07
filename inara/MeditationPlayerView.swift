import SwiftUI
import AVFoundation
import MediaPlayer

struct MeditationPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let folder: String
    // When embedded inside a matched-geometry card, disable the view's own background
    let showsBackground: Bool = true
    @State private var isPlaying = false
    @State private var timeRemaining = 0
    @State private var totalDuration = 0
    @State private var timer: Timer?
    @State private var progress: Double = 0.0
    @State private var showingBottomSheet = false
    @State private var isScrubbing = false
    
    @State private var soundscapePlayer: AVAudioPlayer?
    @State private var openingNarrationPlayer: AVAudioPlayer?
    @State private var closingNarrationPlayer: AVAudioPlayer?
    @State private var soundscapeVolume: Double = 0.5
    @State private var narrationVolume: Double = 0.5
    
    @State private var soundscapeTimestamp: TimeInterval = 0
    @State private var narrationTimestamp: TimeInterval = 0
    @State private var closingNarrationStartTime: TimeInterval = 0
    @State private var closingNarrationDuration: TimeInterval = 0
    
    var body: some View {
        // Player screen background can be disabled when embedded
        ZStack {
            
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(AppColors.transsparent)
                            .stroke(AppColors.circleStroke, style: StrokeStyle(lineWidth: 1, lineCap: .round))
                            .frame(width: 220, height: 220)
                        if isPlaying {
                            Circle()
                                .trim(from: 0, to: progress)
                                .stroke(AppColors.progressActive, style: StrokeStyle(lineWidth: isScrubbing ? 8 : 2, lineCap: .round))
                                .frame(width: 221, height: 221)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 0.3), value: progress)
                                .animation(.easeInOut(duration: 0.2), value: isScrubbing)
                        } else if progress > 0 {
                            Circle()
                                .trim(from: 0, to: progress)
                                .stroke(AppColors.progressPaused, style: StrokeStyle(lineWidth: isScrubbing ? 8 : 2, lineCap: .round))
                                .frame(width: 221, height: 221)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 0.3), value: progress)
                                .animation(.easeInOut(duration: 0.2), value: isScrubbing)
                        }
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 280, height: 280)
                            .contentShape(Circle())
                        Button(action: { togglePlayPause() }) {
                            Circle()
                                .fill(AppColors.transsparent)
                                .frame(width: 72, height: 72)
                                .overlay(
                                    Image(systemName: buttonIcon)
                                        .font(.system(size: 34, weight: .medium))
                                        .foregroundColor(AppColors.buttonIcon)
                                )
                        }
                    }
                    .frame(width: 309, height: 309)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                handleScrub(value: value)
                            }
                            .onEnded { value in
                                finishScrub(value: value)
                            }
                    )
                }
                Text(timeString)
                    .font(.system(size: 16, weight: .semibold))
                    .tracking(2)
                    .foregroundColor(AppColors.tulum)
                    .padding(.vertical, 48)
                Spacer()
                HStack {
                    Button(action: { showingBottomSheet = true }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(AppColors.tulum)
                            .frame(width: 36, height: 36)
                    }
                    Spacer()
                    Button(action: { print("AirPlay button tapped") }) {
                        Image(systemName: "airplay.audio")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(AppColors.tulum)
                            .frame(width: 36, height: 36)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(Color("text"))
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .tint(AppColors.white)
            }
        }
        .sheet(isPresented: $showingBottomSheet) {
            BottomSheetView(
                soundscapeVolume: $soundscapeVolume,
                narrationVolume: $narrationVolume,
                onVolumeChange: updateAudioVolumes
            )
        }
        .onAppear {
            resetProgress()
            Task { 
                try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
                setupAudio()
                setupRemoteCommands()
                configureNowPlayingInfo()
            }
        }
        .onDisappear {
            stopTimer()
            soundscapePlayer?.stop()
            openingNarrationPlayer?.stop()
            closingNarrationPlayer?.stop()
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            teardownRemoteCommands()
        }
    }
    
    private var buttonIcon: String {
        if !isPlaying && progress == 0 { return "play.fill" }
        if isPlaying { return "pause.fill" }
        return "play.fill"
    }
    
    private var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func togglePlayPause() {
        isPlaying.toggle()
        if isPlaying {
            resumeAudio()
            timeRemaining = max(0, totalDuration - Int(soundscapeTimestamp))
            startTimer()
            updateNowPlayingPlayback(isPlaying: true)
        } else {
            stopTimer()
            pauseAudio()
            updateNowPlayingPlayback(isPlaying: false)
        }
    }
    
    private func pauseAudio() {
        if let soundscape = soundscapePlayer {
            soundscapeTimestamp = soundscape.currentTime
            soundscape.pause()
        }
        if let opening = openingNarrationPlayer, opening.isPlaying {
            narrationTimestamp = opening.currentTime
            opening.pause()
        }
        if let closing = closingNarrationPlayer, closing.isPlaying {
            let remainingTime = closing.duration - closing.currentTime
            narrationTimestamp = closingNarrationDuration - remainingTime
            closing.pause()
        }
    }
    
    private func resumeAudio() {
        if let soundscape = soundscapePlayer {
            soundscape.currentTime = soundscapeTimestamp
            soundscape.play()
        }
        if let opening = openingNarrationPlayer, opening.duration > 0, soundscapeTimestamp < closingNarrationStartTime {
            opening.currentTime = narrationTimestamp
            opening.play()
        }
        if let closing = closingNarrationPlayer, closing.duration > 0, soundscapeTimestamp >= closingNarrationStartTime {
            closing.currentTime = narrationTimestamp
            closing.play()
        }
    }
    
    private func startTimer() {
        guard isPlaying, timer == nil else { return }
        let current = Int(soundscapePlayer?.currentTime ?? soundscapeTimestamp)
        timeRemaining = max(0, totalDuration - current)
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
                updateProgress()
                updateNowPlayingElapsed()
                let elapsed = Double(totalDuration - timeRemaining)
                if elapsed >= closingNarrationStartTime && closingNarrationPlayer?.isPlaying == false {
                    playClosingNarration()
                }
            } else {
                stopTimer()
                isPlaying = false
                resetProgress()
                soundscapePlayer?.stop()
                updateNowPlayingPlayback(isPlaying: false)
            }
        }
    }
    
    private func stopTimer() { timer?.invalidate(); timer = nil }
    
    private func updateProgress() {
        guard totalDuration > 0 else { return }
        let elapsed = totalDuration - timeRemaining
        progress = Double(elapsed) / Double(totalDuration)
    }
    
    private func resetProgress() {
        progress = 0.0
        timeRemaining = totalDuration
        soundscapeTimestamp = 0
        narrationTimestamp = 0
    }
    
    private func setupAudio() {
        setupAudioSession()
        setupSoundscape()
        setupOpeningNarration()
        setupClosingNarration()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error setting up audio session: \(error)")
        }
    }
    
    private func setupSoundscape() {
        let possibleNames = ["soundscape", "Soundscape", "SOUNDSCAPE"]
        let possibleExtensions = ["mp3", "m4a", "wav", "aac"]
        var possiblePaths = [folder]
        possiblePaths.append(contentsOf: ["audio/calming", "audio", "calming", ""]) 
        for path in possiblePaths {
            for name in possibleNames {
                for ext in possibleExtensions {
                    if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: path.isEmpty ? nil : path) {
                        loadSoundscape(from: url)
                        configureNowPlayingInfo()
                        return
                    }
                }
            }
        }
    }
    
    private func loadSoundscape(from url: URL) {
        do {
            soundscapePlayer = try AVAudioPlayer(contentsOf: url)
            soundscapePlayer?.numberOfLoops = -1
            soundscapePlayer?.volume = Float(soundscapeVolume)
            soundscapePlayer?.prepareToPlay()
            if let duration = soundscapePlayer?.duration {
                totalDuration = Int(duration)
                timeRemaining = totalDuration
                if closingNarrationDuration > 0 {
                    closingNarrationStartTime = duration - closingNarrationDuration
                }
                configureNowPlayingInfo()
            }
        } catch {
            print("Error loading soundscape: \(error)")
        }
    }
    
    private func setupOpeningNarration() {
        let possibleNames = ["opening", "Opening", "OPENING", "intro", "Intro", "INTRO"]
        let possibleExtensions = ["mp3", "m4a", "wav", "aac"]
        var possiblePaths = [folder]
        possiblePaths.append(contentsOf: ["audio/calming", "audio", "calming", ""]) 
        for path in possiblePaths {
            for name in possibleNames {
                for ext in possibleExtensions {
                    if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: path.isEmpty ? nil : path) {
                        loadOpeningNarration(from: url)
                        return
                    }
                }
            }
        }
    }
    
    private func loadOpeningNarration(from url: URL) {
        do {
            openingNarrationPlayer = try AVAudioPlayer(contentsOf: url)
            openingNarrationPlayer?.volume = Float(narrationVolume)
            openingNarrationPlayer?.prepareToPlay()
        } catch {
            print("Error loading opening narration: \(error)")
        }
    }
    
    private func setupClosingNarration() {
        let possibleNames = ["closing", "Closing", "CLOSING", "outro", "Outro", "OUTRO", "end", "End", "END"]
        let possibleExtensions = ["mp3", "m4a", "wav", "aac"]
        var possiblePaths = [folder]
        possiblePaths.append(contentsOf: ["audio/calming", "audio", "calming", ""]) 
        for path in possiblePaths {
            for name in possibleNames {
                for ext in possibleExtensions {
                    if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: path.isEmpty ? nil : path) {
                        loadClosingNarration(from: url)
                        return
                    }
                }
            }
        }
    }
    
    private func loadClosingNarration(from url: URL) {
        do {
            closingNarrationPlayer = try AVAudioPlayer(contentsOf: url)
            closingNarrationPlayer?.volume = Float(narrationVolume)
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
    
    private func playClosingNarration() {
        guard let player = closingNarrationPlayer, player.duration > 0 else { return }
        let currentBaseTime = soundscapePlayer?.currentTime ?? soundscapeTimestamp
        let relativeTime = max(0, currentBaseTime - closingNarrationStartTime)
        player.currentTime = min(relativeTime, player.duration)
        player.play()
    }
    
    private func updateAudioVolumes() {
        soundscapePlayer?.volume = Float(soundscapeVolume)
        openingNarrationPlayer?.volume = Float(narrationVolume)
        closingNarrationPlayer?.volume = Float(narrationVolume)
    }

    // MARK: - Now Playing / Remote Commands

    private func configureNowPlayingInfo() {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: "Inara",
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
            MPMediaItemPropertyPlaybackDuration: Double(totalDuration),
            MPNowPlayingInfoPropertyElapsedPlaybackTime: Double(totalDuration - timeRemaining)
        ]
        if let image = UIImage(named: "logo") {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            info[MPMediaItemPropertyArtwork] = artwork
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func updateNowPlayingPlayback(isPlaying: Bool) {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = Double(totalDuration - timeRemaining)
        info[MPMediaItemPropertyPlaybackDuration] = Double(totalDuration)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func updateNowPlayingElapsed() {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = Double(totalDuration - timeRemaining)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.playCommand.addTarget { _ in
            if !isPlaying { togglePlayPause() }
            return .success
        }
        commandCenter.pauseCommand.addTarget { _ in
            if isPlaying { togglePlayPause() }
            return .success
        }
        commandCenter.togglePlayPauseCommand.addTarget { _ in
            togglePlayPause(); return .success
        }
    }

    private func teardownRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.togglePlayPauseCommand.removeTarget(nil)
    }
    
    private func handleScrub(value: DragGesture.Value) {
        isScrubbing = true
        let center = CGPoint(x: 140, y: 140)
        let offset = CGPoint(x: value.location.x - center.x, y: value.location.y - center.y)
        var angle = atan2(offset.y, offset.x)
        if angle < 0 { angle += 2 * .pi }
        let normalizedAngle = (angle + .pi/2).truncatingRemainder(dividingBy: 2 * .pi)
        let progressPercentage = normalizedAngle / (2 * .pi)
        let scrubbedTime = Double(totalDuration) * progressPercentage
        let adjustedScrubbedTime = min(max(0, scrubbedTime), Double(totalDuration))
        progress = progressPercentage
        timeRemaining = totalDuration - Int(adjustedScrubbedTime)
        seekToTime(adjustedScrubbedTime)
    }
    
    private func finishScrub(value: DragGesture.Value) {
        isScrubbing = false
        timeRemaining = max(0, totalDuration - Int(soundscapeTimestamp))
        if isPlaying {
            resumeAudio(); startTimer()
        } else {
            isPlaying = true; resumeAudio(); startTimer()
        }
    }
    
    private func seekToTime(_ time: TimeInterval) {
        timeRemaining = max(0, totalDuration - Int(time))
        progress = totalDuration > 0 ? (time / Double(totalDuration)) : 0
        if let soundscape = soundscapePlayer { soundscape.currentTime = time }
        openingNarrationPlayer?.stop()
        closingNarrationPlayer?.stop()
        if let opening = openingNarrationPlayer, time < opening.duration {
            opening.currentTime = time
            if isPlaying { opening.play() }
        }
        if let closing = closingNarrationPlayer, time >= closingNarrationStartTime {
            let narrationTime = max(0, time - closingNarrationStartTime)
            closing.currentTime = narrationTime
            if isPlaying { closing.play() }
        }
        soundscapeTimestamp = time
        if let opening = openingNarrationPlayer, time < opening.duration {
            narrationTimestamp = time
        } else if time >= closingNarrationStartTime {
            narrationTimestamp = max(0, time - closingNarrationStartTime)
        } else {
            narrationTimestamp = 0
        }
    }
}

#Preview {
    MeditationPlayerView(
        title: "CALM",
        folder: "audio/calming"
    )
}


