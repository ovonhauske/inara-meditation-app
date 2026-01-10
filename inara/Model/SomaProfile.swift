//
//  SomaProfile.swift
//  inara
//
//  Created by Oscar von Hauske on 1/10/26.
//


import SwiftData
import Foundation

// The "Master Profile" - There is usually only one of these per user.
@Model
class SomaProfile {
    // 1. The "Big Three" Soma Categories
    // We separate these so the AI doesn't get confused between physical and mental states.
    var physicalPattern: String  // e.g. "Jaw tension is a recurring signal of stress."
    var emotionalPattern: String // e.g. "Anxiety peaks on Sunday evenings."
    var environmentalPattern: String // e.g. "Deepest focus occurs in early mornings."
    
    // 2. The "Rolling Summary"
    // A concise 100-word bio used for quick context injection.
    var summary: String 
    
    // 3. Metadata
    var lastUpdated: Date
    var totalReflectionsAnalyzed: Int
    
    // Relationship: The history of specific realizations
    @Relationship(deleteRule: .cascade) var insights: [SomaticInsight]
    
    init(summary: String = "New Practitioner") {
        self.summary = summary
        self.physicalPattern = ""
        self.emotionalPattern = ""
        self.environmentalPattern = ""
        self.lastUpdated = Date()
        self.totalReflectionsAnalyzed = 0
        self.insights = []
    }
    
    // Generates the "Context Payload" for the OpenAI API
    func generateContextPayload() -> String {
        return """
        USER SOMA PROFILE:
        - Physical Tendencies: \(self.physicalPattern.isEmpty ? "Unknown" : self.physicalPattern)
        - Emotional Landscape: \(self.emotionalPattern.isEmpty ? "Unknown" : self.emotionalPattern)
        - Environment/Time: \(self.environmentalPattern.isEmpty ? "Unknown" : self.environmentalPattern)
        
        RECENT INSIGHTS:
        \(self.insights.sorted(by: { $0.dateDetected > $1.dateDetected }).prefix(3).map { "- \($0.text)" }.joined(separator: "\n"))
        """
    }
}

// The "Atomic Insight" - Future-proofing for a "My Patterns" UI
@Model
class SomaticInsight {
    var text: String           // "You tend to hold breath when discussing work."
    var category: String       // "Body", "Mind", or "Environment"
    var confidence: Double     // 0.0 to 1.0 (How sure is the AI?)
    var dateDetected: Date
    var triggeringSession: String // Which meditation sparked this insight?
    
    init(text: String, category: String, confidence: Double, session: String) {
        self.text = text
        self.category = category
        self.confidence = confidence
        self.dateDetected = Date()
        self.triggeringSession = session
    }
}