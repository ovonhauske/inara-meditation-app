import SwiftUI

struct MeditationDetailView: View {
    let meta: MeditationMeta
    let ns: Namespace.ID
    let onClose: () -> Void

    // Content fade-in configuration
    private let contentFadeDelay: Double = 0.6
    private let contentFadeDuration: Double = 0.35
    @State private var contentVisible: Bool = false

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
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(16)
                    }
                }
                .opacity(contentVisible ? 1 : 0)
                .offset(y: contentVisible ? 0 : 6)
                .animation(.easeOut(duration: contentFadeDuration).delay(contentFadeDelay), value: contentVisible)

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

                    MeditationPlayerView(title: meta.title, folder: meta.folder)
                        .frame(maxHeight: .infinity)
                }
                .opacity(contentVisible ? 1 : 0)
                .offset(y: contentVisible ? 0 : 8)
                .animation(.easeOut(duration: contentFadeDuration).delay(contentFadeDelay), value: contentVisible)
            }
        }
        .zIndex(1)
        .transition(AnyTransition.identity)
        .onAppear {
            contentVisible = false
            withAnimation(.easeOut(duration: contentFadeDuration).delay(contentFadeDelay)) {
                contentVisible = true
            }
        }
        .onDisappear {
            contentVisible = false
        }
    }
}

#Preview {
    struct DetailPreview: View {
        @Namespace var ns
        private let meta = MeditationMeta(
            title: "CALM",
            folder: "audio/calming",
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
