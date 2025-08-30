import SwiftUI

struct BottomSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var soundscapeVolume: Double
    @Binding var narrationVolume: Double
    let onVolumeChange: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(alignment: .leading, spacing: 16) {
                Text("SOUNDSCAPE")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.5)
                    .foregroundColor(AppColors.accentDarker)
                    .textCase(.uppercase)
                HStack(spacing: 16) {
                    Button(action: {
                        soundscapeVolume = max(0, soundscapeVolume - 0.1)
                        onVolumeChange()
                    }) {
                        Image(systemName: "speaker.wave.1")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.accentDarker)
                            .frame(width: 24, height: 24)
                    }
                    Slider(value: $soundscapeVolume, in: 0...1)
                        .accentColor(AppColors.accentDarker)
                        .onChange(of: soundscapeVolume) { _ in
                            onVolumeChange()
                        }
                    Button(action: {
                        soundscapeVolume = min(1, soundscapeVolume + 0.1)
                        onVolumeChange()
                    }) {
                        Image(systemName: "speaker.wave.3")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.accentDarker)
                            .frame(width: 24, height: 24)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 16) {
                Text("NARRATION")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.5)
                    .foregroundColor(AppColors.accentDarker)
                    .textCase(.uppercase)
                HStack(spacing: 16) {
                    Button(action: {
                        narrationVolume = max(0, narrationVolume - 0.1)
                        onVolumeChange()
                    }) {
                        Image(systemName: "speaker.wave.1")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.accentDarker)
                            .frame(width: 24, height: 24)
                    }
                    Slider(value: $narrationVolume, in: 0...1)
                        .accentColor(AppColors.accentDarker)
                        .onChange(of: narrationVolume) { _ in
                            onVolumeChange()
                        }
                    Button(action: {
                        narrationVolume = min(1, narrationVolume + 0.1)
                        onVolumeChange()
                    }) {
                        Image(systemName: "speaker.wave.3")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.accentDarker)
                            .frame(width: 24, height: 24)
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}


