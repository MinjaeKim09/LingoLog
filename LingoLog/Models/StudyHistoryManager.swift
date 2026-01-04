import Foundation

class StudyHistoryManager {
    static let shared = StudyHistoryManager()
    
    private let studyDatesKey = "lingolog_study_dates"
    private var cachedDates: Set<String> = []
    
    // Format dates as "YYYY-MM-DD" for simple storage and comparison
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private init() {
        loadDates()
    }
    
    private func loadDates() {
        if let savedDates = UserDefaults.standard.stringArray(forKey: studyDatesKey) {
            cachedDates = Set(savedDates)
        }
    }
    
    func recordStudySession() {
        let today = dateFormatter.string(from: Date())
        if !cachedDates.contains(today) {
            cachedDates.insert(today)
            UserDefaults.standard.set(Array(cachedDates), forKey: studyDatesKey)
        }
    }
    
    func hasStudied(on date: Date) -> Bool {
        let dateString = dateFormatter.string(from: date)
        return cachedDates.contains(dateString)
    }
    
    /// Returns the last N days including today
    func getRecentHistory(days: Int) -> [Date] {
        var dates: [Date] = []
        let calendar = Calendar.current
        let today = Date()
        
        for i in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                dates.append(date)
            }
        }
        
        return dates.reversed() // Oldest to newest
    }
    
    func getCurrentStreak() -> Int {
        var streak = 0
        let calendar = Calendar.current
        let today = Date()
        
        // check if studied today
        let todayString = dateFormatter.string(from: today)
        if cachedDates.contains(todayString) {
            streak += 1
        }
        
        // check previous days
        guard var previousDay = calendar.date(byAdding: .day, value: -1, to: today) else {
            return streak
        }
        while true {
            let dateString = dateFormatter.string(from: previousDay)
            if cachedDates.contains(dateString) {
                streak += 1
                guard let nextDay = calendar.date(byAdding: .day, value: -1, to: previousDay) else {
                    break
                }
                previousDay = nextDay
            } else {
                break
            }
        }
        
        return streak
    }
}
