import SwiftUI

struct OnboardingHScroll: View {
    @State var HScrollViewModel: OnboardingHScrollViewModel = OnboardingHScrollViewModel()
    @State private var selected: Int = 0
    @State private var timer = Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()
    @State private var autoScrollEnabled: Bool = true
    
    init() {
        let pageControl = UIPageControl.appearance()
        pageControl.currentPageIndicatorTintColor = UIColor(AppColors.tulum)
        pageControl.pageIndicatorTintColor =  UIColor(AppColors.tulum.opacity(0.2))
    }
    
    var body: some View {
        let cards = HScrollViewModel.HScrollCards
        
        TabView(selection: $selected) {
            ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                OnboardingHScrollCard(
                    title: card.title,
                    subtitle: card.subtitle,
                    imageName: card.imageName
                )
                .tag(index)
            }
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .gesture(
            DragGesture()
                .onChanged { _ in
                    autoScrollEnabled = false
                }
                .onEnded { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        autoScrollEnabled = true
                    }
                }
        )
        .onReceive(timer) { _ in
            guard autoScrollEnabled else { return }
            let count = cards.count
            guard count > 0 else { return }
            withAnimation{
                selected = (selected + 1) % count
            }
        }
    }
}

#Preview {
    ZStack{
        AppColors.surface.edgesIgnoringSafeArea(.all)
        OnboardingHScroll()
    }
}

