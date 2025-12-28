import SwiftUI

struct MeditationDetailView: View {
    let meta: MeditationDataModel
    let ns: Namespace.ID
    let onClose: () -> Void

    // Content fade-in configuration
    private let contentFadeDelay: Double = 0.6
    private let contentFadeDuration: Double = 0.35
    @State private var contentVisible: Bool = false
    @State private var showExitConfirm: Bool = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            
            let shape = RoundedRectangle(cornerRadius: 30, style: .continuous)
            shape
                .fill(AppColors.surface)
                .overlay(shape.stroke(AppColors.outline, lineWidth: 1))
                .matchedGeometryEffect(id: "card.\(meta.id)", in: ns)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack{
                    Spacer()
                    Button(action: { showExitConfirm = true }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(AppColors.tulum)
                            .padding(16)
                    }
                }
                .opacity(contentVisible ? 1 : 0)
                .offset(y: contentVisible ? 0 : 6)

                Image(meta.imageName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(AppColors.tulum)
                    .frame(height: 64)
                    .matchedGeometryEffect(id: "image.\(meta.id)", in: ns)

                Group {
                    Text(meta.title)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(AppColors.tulum)

                    Text(meta.subtitle)
                        .font(.body)
                        .foregroundColor(AppColors.tulum)

                    MeditationPlayerView(title: meta.title, folder: meta.audiosrc)
                        .frame(maxHeight: .infinity)
                }
                .opacity(contentVisible ? 1 : 0)
                .offset(y: contentVisible ? 0 : 8)
            }
        }
        .zIndex(1)
        .transition(AnyTransition.identity)
        .onAppear {
            contentVisible = false
            DispatchQueue.main.asyncAfter(deadline: .now() + contentFadeDelay) {
                withAnimation(.easeOut(duration: contentFadeDuration)) {
                    contentVisible = true
                }
            }
        }
        .onDisappear {
            contentVisible = false
        }
        .alert("Stop meditation?", isPresented: $showExitConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("End meditation", role: .destructive) { handleClose() }
        } message: {
            Text("Your session will end")
        }
    }

    private func handleClose() {
        withAnimation(.easeOut(duration: contentFadeDuration)) {
            contentVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + contentFadeDuration) {
            onClose()
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
