// ReflectionInputView.swift

import SwiftUI
import SwiftData

struct ReflectionInputView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var somaProfiles: [SomaProfile]
    
    @Binding var isPresented: Bool
    
    let meta: MeditationDataModel
    let ns: Namespace.ID
    
    // Context inputs
    var meditationTitle: String
    var duration: Int
    
    @State private var text: String = ""
    @State private var headline: String = "How do you feel right now?"
    @State private var isAnalyzing: Bool = false
    @FocusState private var isFocused: Bool
    
    private let aiClient = AIClient()
    
    var body: some View {
        ZStack {
            // Full-screen background, but keep content respecting top safe area
            AppColors.surface.ignoresSafeArea()

            if isAnalyzing {
                VStack(spacing: 20) {
                    ProgressView()
                    Text("Integrating...")
                        .subtitleStyle()
                }
                // Keep progress UI centered and under the top safe area
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                content
            }
        }
    }
    
    // Main content: respects top safe area; only bottom adjusts for keyboard
    var content: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // Top spacer to give breathing room below the status/Dynamic Island
                    HStack{}.frame(height: 80)
                    
                    // Header
                    VStack {
                        Image(meta.imageName)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(AppColors.tulum)
                            .frame(height: 48)
                            .matchedGeometryEffect(id: "image.\(meta.id)", in: ns)
                        
                        Text(meta.title)
                            .titleStyle()
                            .matchedGeometryEffect(id: "title.\(meta.id)", in: ns)
                        
                        Text(meta.subtitle)
                            .subtitleStyle()
                            .matchedGeometryEffect(id: "subtitle.\(meta.id)", in: ns)
                    }
                    
                    // Prompt and explainer
                    VStack(alignment: .center, spacing: 4) {
                        Text(headline.uppercased())
                            .titleStyle()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .multilineTextAlignment(.center)
                        
                        Text("Add a note to help uncover patterns in your practice over time")
                            .subtitleStyle()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    // Text input
                    ZStack(alignment: .topLeading) {
                        if text.isEmpty {
                            Text("I noticed...")
                                .subtitleStyle()
                                .opacity(0.6)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 24)
                                .allowsHitTesting(false)
                        }
                        
                        TextEditor(text: $text)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .frame(height: 100)
                            .padding(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppColors.outline, lineWidth: 2)
                            )
                            .focused($isFocused)
                    }
                }
                .padding(16)
            }
            
            // CTA row stays above the keyboard via standard layout resizing
            HStack {
                OutlineButton(text: "Not now", action: {
                    isPresented = false
                }, collapse: false)
                
                OutlineButton(text: "Save reflection", action: {
                    saveReflection()
                }, collapse: false)
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            isFocused = true
        }
    }
    
    private func saveReflection() {
        guard text.count > 5 else { return }
        isAnalyzing = true
        
        Task {
            do {
                let context = "Afternoon meditation. User is a beginner."
                let analysis = try await aiClient.analyzeReflection(text: text, context: context)
                
                // Update or Create Profile
                let profile = somaProfiles.first ?? SomaProfile()
                if somaProfiles.isEmpty {
                    modelContext.insert(profile)
                }
                
                profile.summary = analysis.summary
                profile.totalReflectionsAnalyzed += 1
                profile.lastUpdated = Date()
                
                // Add Insights
                for insightData in analysis.insights {
                    let insight = SomaticInsight(
                        text: insightData.text,
                        category: insightData.category,
                        confidence: insightData.confidence,
                        session: "Current Session"
                    )
                    modelContext.insert(insight)
                    profile.insights.append(insight)
                }
                
                try modelContext.save()
                
                await MainActor.run {
                    isAnalyzing = false
                    isPresented = false
                }
                
            } catch {
                print("Failed to analyze: \(error)")
                await MainActor.run {
                    isAnalyzing = false
                    isPresented = false
                }
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @Namespace var ns
        @State var isPresented = true
        let meta = MeditationDataModel(title: "Calm", audiosrc: "nil", subtitle: "Inara", imageName: "calming")
        
        var body: some View {
            ReflectionInputView(isPresented: $isPresented, meta: meta, ns: ns, meditationTitle: "Something", duration: 5)
        }
    }
    return PreviewWrapper()
}
