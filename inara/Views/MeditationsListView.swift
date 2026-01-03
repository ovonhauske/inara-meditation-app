import SwiftUI



/// A view that shows all the meditations available as tappable cards
struct MeditationsListView: View {
    
    @State var meditationViewModel: MeditationViewModel = MeditationViewModel()
    
    @State private var selected: MeditationDataModel? = nil
    @State private var isListVisible: Bool = true
    @Namespace private var cardNamespace
    
    @State private var showingShop = false
    @State private var shopURL: URL? = URL(string: "https://www.inarasense.com/shop")
    
    var body: some View {
        // Main content
        ZStack {
            VStack {
                LogoView()
                
                ForEach(self.meditationViewModel.meditations, id: \.id) { meditation in
                    let isActive = (selected?.id == meditation.id)
                    
                    Button {
                        withAnimation(AppAnimation.spring) {
                            selected = meditation
                            isListVisible = false
                        }
                    } label: {
                        MeditationCard(
                            title: meditation.title,
                            subtitle: meditation.subtitle,
                            imageName: meditation.imageName,
                            id: meditation.id,
                            ns: cardNamespace
                        )
                    }
                    .opacity(isActive ? 0 : 1)           // keep layout; just not visible
                    .allowsHitTesting(!isActive)         // avoid taps leaking
                    
                }
                OutlineButton(text: "Shop Fragrances", icon: "cart") {
                    showingShop = true
                }
            }
            .padding(.horizontal, 16)
            .fadeSlideIn(isVisible: $isListVisible, response: 1, damping: 0.85, offsetY: 18)
            
            //expanded card
            
            if let current = selected {
                MeditationDetailView(meta: current, ns: cardNamespace) {
                    withAnimation(AppAnimation.spring) {
                        isListVisible = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
                        selected = nil
                    }
                }
                .zIndex(1)
            }
        }
        .sheet(isPresented: $showingShop) {
            if let url = shopURL {
                SafariView(url: url)
                    .ignoresSafeArea()
            } else {
                Text("Unable to load shop")
                    .padding()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
}
#Preview {
    MeditationsListView()
}
