import SwiftUI

struct MeditationDetailView: View {
    let meta: MeditationDataModel
    let ns: Namespace.ID
    let onClose: () -> Void

    // Content fade-in configuration
    // Content fade-in configuration
    @State private var contentVisible: Bool = false
    @State private var showExitConfirm: Bool = false
    @State private var showReflection: Bool = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
//            if !showReflection {
                VStack(spacing: 16) {
                    HStack{}
                        .frame(height: 40)
                    HStack{
                        Spacer()
                        Button(action: { showExitConfirm = true }) {
                            Image(systemName: "xmark")
                                .iconStyle()
                                .padding(16)
                        }
                    }
                    Group {
                        
                        Image(meta.imageName)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(AppColors.tulum)
                            .frame(height: 64)
                            .matchedGeometryEffect(id: "image.\(meta.id)", in: ns)

                        
                        Text(meta.title)
                            .titleStyle()
                            .matchedGeometryEffect(id: "title.\(meta.id)", in: ns)

                        Text(meta.subtitle)
                            .subtitleStyle()
                            .matchedGeometryEffect(id: "subtitle.\(meta.id)", in: ns)
                        
//                        if !showReflection {
                            MeditationPlayerView(title: meta.title, folder: meta.audiosrc)
                                .frame(maxHeight: .infinity)
//                        }
                    }
                 //   .fadeSlideIn(isVisible: $contentVisible)
                }
//            }
/*            if showReflection {
                ReflectionInputView(
                    isPresented: $showReflection,
                    meditationTitle: meta.title,
                    duration: 900 // Default to 15m for now until we surface actual duration
                )
                .zIndex(2)
            } */
        }
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(AppColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(AppColors.outline, lineWidth: 1)
                )
                .matchedGeometryEffect(id: "card.\(meta.id)", in: ns)
        )
        .frame(maxWidth: .infinity, alignment: .init(horizontal: .center, vertical: .top))
        .ignoresSafeArea()
        .zIndex(1)
        .transition(AnyTransition.identity)
        .springAnimated(value: contentVisible)
        .alert("Stop meditation?", isPresented: $showExitConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("End meditation", role: .destructive) { 
                // Don't close immediately, show reflection
                // showReflection = true 
                handleClose()
            }
        } message: {
            Text("Your session will end")
        }
//        .onChange(of: showReflection) { oldValue, newValue in
//            if !newValue {
//                // If it was true and now false, user dismissed reflection -> Close detail
//                handleClose()
//            }
//        }
    }

    private func handleClose() {
        contentVisible = false
        withAnimation(AppAnimation.spring) {
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
            }
        }
    }
    return DetailPreview()
}
