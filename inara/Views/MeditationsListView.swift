import SwiftUI



/// A view that shows all the meditations available as tappable cards
struct MeditationsListView: View {
    
    @State var meditationViewModel: MeditationViewModel = MeditationViewModel()
    
    @State private var selected: MeditationDataModel? = nil
    @State private var isExpanded: Bool = false
    @Namespace private var cardNamespace

    // Animation constants
    private let closeSpring = Animation.spring(response: 0.6, dampingFraction: 0.85)
    private let fadeDuration: Double = 0.6
    private let deselectDelay: Double = 0.30

    var body: some View {
        // Main content
        ZStack {
            VStack() {
                logoView()
                
                ForEach(self.meditationViewModel.meditations, id: \.id) { meditation in
                    let isActive = (selected?.id == meditation.id)

                    Button {
                            selected = meditation
                            isExpanded = true
                        
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
            }
            .padding(.horizontal, 16)
            .opacity(isExpanded ? 0 : 1)
            .disabled(isExpanded)
            //expanded card
          if let current = selected {
                  MeditationDetailView(meta: current, ns: cardNamespace) {
                      isExpanded = false
                      DispatchQueue.main.asyncAfter(deadline: .now()) {
                          withAnimation(closeSpring) {
                              selected = nil
                          }
                      }
                  }
                  .zIndex(1)
              }
            }
 
            

        }
    
    }
    
    
#Preview {
    MeditationsListView()
}
