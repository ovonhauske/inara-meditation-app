import SwiftUI

struct MeditationPlayerView: View {
    @StateObject private var vm: MeditationPlayerViewModel

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
        .onAppear { vm.onAppear() }
        .onDisappear { vm.onDisappear() }
    }

    private var playerDial: some View {
        ZStack {
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

            Button(action: vm.togglePlayPause) {
                Circle()
                    .fill(AppColors.transparent)
                    .frame(width: 72, height: 72)
                    .overlay(
                        Image(systemName: buttonIcon)
                            .largeIconStyle()
                            .opacity((!vm.isPlaying && vm.progress == 0) ? 0 : 1)
                    )
            }

            if !vm.isPlaying && vm.progress == 0 {
                Text("START")
                    .startButtonStyle()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    vm.scrubChanged(location: value.location,
                                    center: CGPoint(x: 140, y: 140),
                                    radius: 140);
                    withAnimation(.easeInOut){
                        stroke = 12}

                }
                .onEnded { value in
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
