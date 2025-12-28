//
//  VolumeSlider.swift
//  inara
//
//  Reusable volume control component
//

import SwiftUI

struct VolumeSlider: View {
    let label: String
    @Binding var volume: Double
    let onVolumeChange: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(label)
                .subtitleStyle()
            HStack(spacing: 16) {
                Button(action: {
                    volume = max(0, volume - 0.1)
                    onVolumeChange()
                }) {
                    Image(systemName: "speaker.wave.1")
                        .iconStyle()
                        .frame(width: 24, height: 24)
                }
                Slider(value: $volume, in: 0...1)
                    .accentColor(AppColors.tulum)
                    .onChange(of: volume) {
                        onVolumeChange()
                    }
                Button(action: {
                    volume = min(1, volume + 0.1)
                    onVolumeChange()
                }) {
                    Image(systemName: "speaker.wave.3")
                        .iconStyle()
                        .frame(width: 24, height: 24)
                }
            }
        }
    }
}

