import SwiftUI

struct StreakCalendarView: View {
    let daysToDisplay = 14
    let historyManager: StudyHistoryManager
    
    init(historyManager: StudyHistoryManager = .shared) {
        self.historyManager = historyManager
    }
    
    private var dates: [Date] {
        historyManager.getRecentHistory(days: daysToDisplay)
    }
    
    private let weekDays = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                ForEach(0..<7, id: \.self) { index in
                    Text(weekDays[index])
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                
                ForEach(dates, id: \.self) { date in
                    let hasStudied = historyManager.hasStudied(on: date)
                    let isToday = Calendar.current.isDateInToday(date)
                    
                    ZStack {
                        Circle()
                            .fill(
                                hasStudied
                                    ? Theme.Colors.success
                                    : (isToday ? Theme.Colors.accent.opacity(0.1) : Theme.Colors.inactive.opacity(0.5))
                            )
                            .frame(width: 30, height: 30)
                        
                        if isToday && !hasStudied {
                            Circle()
                                .stroke(Theme.Colors.accent, lineWidth: 1)
                                .frame(width: 30, height: 30)
                        }
                    }
                }
            }
        }
    }
}
