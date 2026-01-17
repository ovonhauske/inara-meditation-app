
import Foundation
import SwiftData

@MainActor
class SomaManager: ObservableObject {
    private let modelContext: ModelContext
    private let aiClient = AIClient()
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Function A: Prepare Question
    func prepareReflectionQuestion(for session: SessionLog) async -> String {
        // 1. Fetch Profile (Create if missing)
        let profile = fetchMasterProfile()
        
        // 2. Call AI
        do {
            return try await aiClient.generateSomaQuestion(context: session, profile: profile)
        } catch {
            print("SomaManager Error (Gen Question): \(error)")
            return "How does your body feel right now?" // Fallback
        }
    }
    
    // MARK: - Function B: Save & Analyze
    func saveAndAnalyzeSession(_ session: SessionLog) async {
        // 1. Insert immediately so UI is responsive
        modelContext.insert(session)
        do {
            try modelContext.save()
        } catch {
            print("Failed to save initial session: \(error)")
        }
        
        // 2. Fetch Profile
        let profile = fetchMasterProfile()
        
        // 3. Call AI Analysis
        do {
            let analysis = try await aiClient.updateSomaProfile(newLog: session, currentProfile: profile)
            
            // 4. Update Profile
            profile.summary = analysis.summary
            profile.lastUpdated = Date()
            profile.totalReflectionsAnalyzed += 1
            
            // Add new insights
            for item in analysis.insights {
                let newInsight = SomaticInsight(
                    text: item.text,
                    category: item.category,
                    confidence: item.confidence,
                    session: session.emotionalCue // Using emotional cue as the session identifier
                )
                modelContext.insert(newInsight)
                profile.insights.append(newInsight)
            }
            
            // 5. Final Save
            try modelContext.save()
            print("Soma Profile Analyzed & Updated.")
            
        } catch {
            print("SomaManager Error (Analysis): \(error)")
        }
    }
    
    // Helper to get the single user profile
    private func fetchMasterProfile() -> SomaProfile {
        let descriptor = FetchDescriptor<SomaProfile>()
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        } else {
            let newProfile = SomaProfile()
            modelContext.insert(newProfile)
            return newProfile
        }
    }
}
