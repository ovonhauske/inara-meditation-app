import SwiftUI

struct MeditationCard: View {
    let title: String
    let subtitle: String
    let imageName: String
    let id: UUID
    let ns: Namespace.ID
    var isSelected: Bool = false
    
    var body: some View {
        
        VStack(spacing: 4) {
            if !isSelected {
                Image(imageName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 48)
                    .foregroundColor(AppColors.tulum)
                    .hidden()
                    .overlay(
                        Image(imageName)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 48)
                            .foregroundColor(AppColors.tulum)
                            .matchedGeometryEffect(id: "image.\(id)", in: ns)
                    )
            } else {
                Image(imageName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 48)
                    .foregroundColor(AppColors.tulum)
            }
                        
            if !isSelected {
               Text(title)
                    .titleStyle()
                    .multilineTextAlignment(.center)
                    .hidden() // Keep layout size
                    .overlay(
                        Text(title)
                            .titleStyle()
                            .multilineTextAlignment(.center)
                            .matchedGeometryEffect(id: "title.\(id)", in: ns)
                    )
            } else {
                 Text(title)
                    .titleStyle()
                    .multilineTextAlignment(.center)
            }
            
            if !isSelected {
               Text(subtitle)
                    .subtitleStyle()
                    .multilineTextAlignment(.center)
                    .hidden()
                    .overlay(
                        Text(subtitle)
                            .subtitleStyle()
                            .multilineTextAlignment(.center)
                            .matchedGeometryEffect(id: "subtitle.\(id)", in: ns)
                    )
            } else {
                 Text(subtitle)
                    .subtitleStyle()
                    .multilineTextAlignment(.center)
            }

        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(AppColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(AppColors.outline, lineWidth: 1)
                )
                .matchedGeometryEffect(id: "card.\(id)", in: ns, isSource: true)
        )

    }
    
    

}



#Preview {
    struct CardPreview: View {
        @Namespace var ns
        var body: some View {
            MeditationCard(
                title: "Inara",
                subtitle: "Calming",
                imageName: "calming",
                id: UUID(),
                ns: ns
            )
            .padding()
        }
    }
    return CardPreview()
}
