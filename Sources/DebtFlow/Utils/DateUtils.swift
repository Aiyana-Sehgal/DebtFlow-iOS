import Foundation

struct DateUtils {
    static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        return f
    }()

    static func freedomDate(from months: Int) -> String {
        let calendar = Calendar.current
        let futureDate = calendar.date(byAdding: .month, value: months, to: Date()) ?? Date()
        return formatter.string(from: futureDate)
    }

    static func monthsToYearsMonths(_ months: Int) -> String {
        let years = months / 12
        let remainingMonths = months % 12
        var result = ""
        if years > 0 {
            result += "\(years) year\(years > 1 ? "s" : "")"
        }
        if remainingMonths > 0 {
            if !result.isEmpty { result += " " }
            result += "\(remainingMonths) month\(remainingMonths > 1 ? "s" : "")"
        }
        return result.isEmpty ? "0 months" : result
    }
}