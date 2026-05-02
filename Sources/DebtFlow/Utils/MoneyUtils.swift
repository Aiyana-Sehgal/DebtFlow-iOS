import Foundation

struct MoneyUtils {
    static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        return f
    }()

    static func format(_ amount: Decimal) -> String {
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$\(amount)"
    }

    static func roundToTwoDecimals(_ value: Decimal) -> Decimal {
        var val = value
        var result = Decimal()
        NSDecimalRound(&result, &val, 2, .plain)
        return result
    }
}