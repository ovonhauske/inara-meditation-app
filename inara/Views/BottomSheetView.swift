import SwiftUI

struct BottomSheetView: View {
    @Binding var soundscapeVolume: Double
    @Binding var narrationVolume: Double
    let onVolumeChange: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            VolumeSlider(
                label: "Soundscape",
                volume: $soundscapeVolume,
                onVolumeChange: onVolumeChange
            )
            VolumeSlider(
                label: "Narration",
                volume: $narrationVolume,
                onVolumeChange: onVolumeChange
            )
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
