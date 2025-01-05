import Foundation

func timeAgoText(from date: Date, relativeTo now: Date = Date()) -> String {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
    
    if let minutes = components.minute {
        if minutes < 1 {
            return "gerade jetzt"
        } else if minutes < 60 {
            return "vor \(minutes) \(minutes == 1 ? "Minute" : "Minuten")"
        } else if let hours = components.hour, hours < 24 {
            return "vor \(hours) \(hours == 1 ? "Stunde" : "Stunden")"
        } else if let days = components.day {
            return "vor \(days) \(days == 1 ? "Tag" : "Tagen")"
        }
    }
    
    return "vor einiger Zeit"
} 