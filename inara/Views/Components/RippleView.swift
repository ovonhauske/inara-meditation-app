import SwiftUI
import CoreHaptics

struct RippleView: View {
    @Binding var trigger: Int
    
    @State private var rippleScale: CGFloat = 0.1
    @State private var rippleOpacity: Double = 0
    @State private var hapticsEngine: CHHapticEngine?
    
    let size: CGFloat
    
    var body: some View {
        Circle()
            .fill(AppColors.outline)
            .frame(width: size, height: size)
            .scaleEffect(rippleScale)
            .opacity(rippleOpacity)
            .allowsHitTesting(false)
            .onChange(of: trigger) { oldValue, newValue in
                triggerRipple()
            }
            .onAppear {
                prepareHaptics()
            }
    }
    
    private func triggerRipple() {
        // Reset to initial state immediately
        rippleScale = 0.1
        rippleOpacity = 0.8
        
        playRippleHaptic()
        
        // Animate outwards
        // DURATION: Adjust this to change how long the ripple animation lasts.
        // NOTE: This should match the haptic duration below.
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
