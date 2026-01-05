import SwiftUI
import CoreHaptics

struct MeditationPlayerView: View {
    @StateObject private var vm: MeditationPlayerViewModel

    @State private var showBreathIndicator: Bool = false
    @State private var breathOpacity: Double = 0
    @State private var rippleScale: CGFloat = 0.1
    @State private var rippleOpacity: Double = 0
    @State private var hapticsEngine: CHHapticEngine?
    
    let playerSize: CGFloat = 220
    @State private var stroke: CGFloat = 2

    init(title: String, folder: String) {
        _vm = StateObject(wrappedValue: MeditationPlayerViewModel(title: title, folder: folder))
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Spacer()

                playerDial
                    .padding(.bottom, 24)

                Text(timeString(vm.timeRemaining))
                    .subtitleStyle()
                    .padding(.vertical, 48)

                Spacer()

                bottomBar
            }
        }
        .sheet(isPresented: $vm.showingBottomSheet) {
            BottomSheetView(
                soundscapeVolume: $vm.soundscapeVolume,
                narrationVolume: $vm.narrationVolume,
                onVolumeChange: vm.updateVolumes
            )
        }
        .onAppear {
            vm.onAppear()
            prepareHaptics()
        }
        .onDisappear { vm.onDisappear() }
    }

    private var playerDial: some View {
        ZStack {
            
            // Ripple Circle - Always present but hidden when inactive
            Circle()
                .fill(AppColors.outline)
                .frame(width: playerSize, height: playerSize)
                .scaleEffect(rippleScale)
                .opacity(rippleOpacity)
                .allowsHitTesting(false)
            
            Circle()
                .fill(AppColors.transparent)
                .stroke(AppColors.outline, style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                .frame(width: playerSize, height: playerSize)

            if vm.progress > 0 {
                Circle()
                    .trim(from: 0, to: vm.progress)
                
                    .stroke(
                        vm.isPlaying ? AppColors.tulum : AppColors.white,
                            style: StrokeStyle(lineWidth: stroke,
                            lineCap: .round))
                    .frame(width: playerSize, height: playerSize)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: vm.progress)
                    .animation(.easeInOut(duration: 0.2), value: vm.isScrubbing)
            }

            Button(action: {
                
                // Show breath indicator when not playing and at the start
                if !vm.isPlaying && vm.progress == 0 {
                    triggerRipple()
                }
                vm.togglePlayPause()

            }) {
                Circle()
                    .fill(AppColors.transparent)
                    .frame(width: 96, height: 96) // Increased tap target
                    .overlay(
                        Image(systemName: buttonIcon)
                            .largeIconStyle()
                            .opacity((!vm.isPlaying && vm.progress == 0) ? 0 : 1)
                    )
            }

            if !vm.isPlaying && vm.progress == 0 {
                Text("START")
                    .startButtonStyle()
                    .allowsHitTesting(false) // Let taps pass through to the button
            }
            
     
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    // Disable scrubbing when in "Start" (intro) state
                    guard vm.progress > 0 || vm.isPlaying else { return }
                    
                    vm.scrubChanged(location: value.location,
                                    center: CGPoint(x: 140, y: 140),
                                    radius: 140);
                    withAnimation(.easeInOut){
                        stroke = 12}

                }
                .onEnded { value in
                    // Disable scrubbing when in "Start" state
                    guard vm.progress > 0 || vm.isPlaying else { return }

                    vm.scrubEnded(location: value.location,
                                center: CGPoint(x: 140, y: 140))
                    withAnimation(.easeInOut){
                        stroke = 4}
                }
        )
        
      
    }

    private var bottomBar: some View {
        HStack {
            Button(action: { vm.showingBottomSheet = true }) {
                Image(systemName: "slider.horizontal.3")
                    .iconStyle()
                    .frame(width: 36, height: 36)
            }
            Spacer()
            Button(action: { /* AirPlay later */ }) {
                Image(systemName: "airplay.audio")
                    .iconStyle()
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 24)
    }

    private var buttonIcon: String {
        vm.isPlaying ? "pause.fill" : "play.fill"
    }

    private func timeString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
    
    private func triggerRipple() {
        // Reset to initial state immediately
        rippleScale = 0.1
        rippleOpacity = 0.8
        
        playRippleHaptic()
        
        // Animate outwards
        withAnimation(.easeOut(duration: 1.2)) {
            rippleScale = 6.0
            rippleOpacity = 0.0
        }
    }
    
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("📳 Device does not support CoreHaptics")
            return
        }
        
        do {
            hapticsEngine = try CHHapticEngine()
            
            // Add robustness handlers
            hapticsEngine?.resetHandler = { [weak hapticsEngine] in
                print("📳 Haptic engine resetting...")
                do {
                    try hapticsEngine?.start()
                } catch {
                    print("📳 Failed to restart haptic engine: \(error)")
                }
            }
            
            hapticsEngine?.stoppedHandler = { reason in
                print("📳 Haptic engine stopped: \(reason)")
            }
            
            try hapticsEngine?.start()
            print("📳 Haptic engine started")
        } catch {
            print("📳 Haptic engine creation failed: \(error)")
        }
    }

    private func playRippleHaptic() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("📳 Play Haptic skipped: Not supported on this device/simulator")
            return
        }
        
        // Ensure engine is running
        if let engine = hapticsEngine {
            do {
               try engine.start() 
            } catch {
                print("📳 Engine failed to start for playback: \(error)")
            }
        }
        
        // DURATION: Adjust this to change how long the ripple vibration lasts.
        // NOTE: This should match the visual animation duration in 'triggerRipple()'
        let duration: TimeInterval = 1.2

        var events: [CHHapticEvent] = []
        
        // 1. TRANSIENT EVENT: The initial "tap" sensation
        let startTransient = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                // INTENSITY: How strong the initial tap feels (0.0 - 1.0)
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                // SHARPNESS: How crisp (vs dull) the tap feels (0.0 - 1.0)
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            ],
            relativeTime: 0
        )
        events.append(startTransient)

        // 2. CONTINUOUS EVENT: The underlying "hum" that fades out
        let continuous = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                // Base INTENSITY for the hum
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                // Base SHARPNESS for the hum
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
            ],
            relativeTime: 0,
            duration: duration
        )
        events.append(continuous)

        // 3. PARAMETER CURVES: How the sensation changes over time (Fading Out)
        
        // Intensity Fade Out Logic
        let intensityCurve = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                // Start value (should match continuous base intensity)
                CHHapticParameterCurve.ControlPoint(relativeTime: 0.0, value: 0.4),
                // End value (0.0 = completely faded out)
                CHHapticParameterCurve.ControlPoint(relativeTime: duration, value: 0.0)
            ],
            relativeTime: 0
        )
        
        // Sharpness Fade Out Logic
        let sharpnessCurve = CHHapticParameterCurve(
            parameterID: .hapticSharpnessControl,
            controlPoints: [
                // Start value (should match continuous base sharpness)
                CHHapticParameterCurve.ControlPoint(relativeTime: 0.0, value: 0.2),
                // End value
                CHHapticParameterCurve.ControlPoint(relativeTime: duration, value: 0.0)
            ],
            relativeTime: 0
        )

        do {
            let pattern = try CHHapticPattern(events: events, parameterCurves: [intensityCurve, sharpnessCurve])
            let player = try hapticsEngine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
            print("📳 Playing ripple haptic pattern")
        } catch {
            print("📳 Failed to play haptic pattern: \(error)")
        }
    }
}


#Preview {
    struct DetailPreview: View {
        @Namespace var ns
        private let meta = MeditationDataModel(
            title: "CALM",
            audiosrc: "audio/calming",
            subtitle: "Inara",
            imageName: "calming"
            
        )

        var body: some View {
            ZStack {
                AppColors.surface.ignoresSafeArea()
                MeditationDetailView(meta: meta, ns: ns) { }
                    .padding()
            }
        }
    }
    return DetailPreview()
}
