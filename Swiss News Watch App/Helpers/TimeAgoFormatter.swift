import Foundation

func timeAgoText(from date: Date, relativeTo now: Date = Date()) -> String {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
    
    if let minutes = components.minute {
        if minutes < 1 {
            return String(localized: "gerade jetzt")
        } else if minutes < 60 {
            let minuteText = minutes == 1 ? String(localized: "Minute") : String(localized: "Minuten")
            return String(localized: "vor \(minutes) \(minuteText)")
        } else if let hours = components.hour, hours < 24 {
            let hourText = hours == 1 ? String(localized: "Stunde") : String(localized: "Stunden")
            return String(localized: "vor \(hours) \(hourText)")
        } else if let days = components.day {
            let dayText = days == 1 ? String(localized: "Tag") : String(localized: "Tagen")
            return String(localized: "vor \(days) \(dayText)")
        }
    }
    
    return String(localized: "vor einiger Zeit")
} 