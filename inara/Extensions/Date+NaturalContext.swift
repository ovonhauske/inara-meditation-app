import Foundation

extension Date {
    /// Returns a gentle, relative time string to complete the sentence: "You meditated..."
    func getNaturalContext() -> String {
        let calendar = Calendar.current
        let now = Date()
        
        // Check if older than 7 days
        if let daysAgo = calendar.dateComponents([.day], from: self, to: now).day, daysAgo > 7 {
            return "a while ago"
        }
        
        // Define Day Parts
        let hour = calendar.component(.hour, from: self)
        var dayPart = ""
        
        switch hour {
        case 5..<12:
            dayPart = "morning"
        case 12..<17:
            dayPart = "afternoon"
        case 17..<21:
            dayPart = "evening"
        default: // 21..<24 or 0..<5
            dayPart = "night"
        }
        
        // Check if Today
        if calendar.isDateInToday(self) {
            return "this \(dayPart)"
        }
        
        // Check if Yesterday
        if calendar.isDateInYesterday(self) {
            return "yesterday \(dayPart)"
        }
        
        // Check if within last 7 days (but not today/yesterday)
        // We know it's <= 7 days because of the first check.
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE" // Full day name (e.g., Tuesday)
        let dayName = dayFormatter.string(from: self)
        
        return "last \(dayName)"
    }
}
