//
//  ReflectionInputView.swift
//  inara
//
//  Created by Oscar von Hauske on 1/10/26.
//

import SwiftUI
import SwiftData

struct ReflectionInputView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var somaProfiles: [SomaProfile]
    
    @Binding var isPresented: Bool
    
    // Context inputs
    var meditationTitle: String
    var duration: Int
    
    @State private var text: String = "I noticed..."
    @State private var headline: String = "Integrate" // Simpler default
    @State private var isAnalyzing: Bool = false
    @State private var isLoadingHeadline: Bool = true
    
    private let aiClient = AIClient()
    
    var body: some View {
        ZStack {
            AppColors.surface.ignoresSafeArea()
            
            if isAnalyzing {
                VStack(spacing: 20) {
                    ProgressView()
                    Text("Integrating...")
                        .subtitleStyle()
                }
            } else {
                content
            }
        }
        .onAppear {
            generateHeadline()
        }
    }
    
    var content: some View {
        VStack(spacing: 24) {
            Image("reflect")
                .resizable()
                .scaledToFit()
                .frame(width: 80)
           
            VStack(alignment: .center, spacing: 4) {
                // 1. HEADLINE
                if isLoadingHeadline {
                    ProgressView()
                        .padding()
                } else {
                    Text(headline.uppercased())
                        .titleStyle()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                }
                
                // 2. EXPLAINER
                Text("Add a note to help uncover patterns in your practice over time")
                    .subtitleStyle()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
           
            // 3. THE FIELD
            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .frame(height: 100)
                .padding(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.outline, lineWidth: 2)
                )
    
            
           
            // 4. CTAS
            HStack {
                OutlineButton(text: "Not now", action: {
                isPresented = false
                }, collapse: false)
                
                OutlineButton(text: "Save reflection", action: {
                    saveReflection()
                }, collapse: false)
            }

        }
        .padding(16)
    }
    
    private func generateHeadline() {
        // Don't re-generate if we already have a custom one
        guard headline == "Integrate" else { return }
        
        Task {
            isLoadingHeadline = true
            do {
                let context = "Meditation: \(meditationTitle), Duration: \(duration/60) min. User context: Beginner."
                let newHeadline = try await aiClient.generateHeadline(context: context)
                await MainActor.run {
                        headline = newHeadline
                        isLoadingHeadline = false
                }
            } catch {
                print("Failed to generate headline: \(error)")
                await MainActor.run {
                    // Fallback to a generic but different question so they see a change

                        headline = "How do you feel right now?"
                        isLoadingHeadline = false
                    
                }
            }
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
                
                try modelContext.save() // Only necessary if auto-save isn't catching it immediately, but safer.
                
                await MainActor.run {
                    isAnalyzing = false
                    isPresented = false
                }
                
            } catch {
                print("Failed to analyze: \(error)")
                // Even if AI fails, we close the view so the user isn't stuck.
                // Optionally we could show an error toast, but preventing stuck state is priority.
                await MainActor.run { 
                    isAnalyzing = false 
                    isPresented = false
                }
            }
        }
    }
}

#Preview{
    ReflectionInputView(isPresented: Binding<Bool>(get: {false}, set: {_ in}),  meditationTitle: "Something", duration: 5)
}
