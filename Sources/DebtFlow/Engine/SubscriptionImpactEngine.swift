import Foundation

struct SubscriptionImpactEngine {
    static func calculateImpact(subscriptions: [Subscription], extraPayment: Decimal, payoffMonths: Int, totalInterest: Decimal) -> SubscriptionImpact {
        let monthlyTotal = subscriptions.reduce(0) { $0 + $1.monthlyCost }
        let threeYearCost = monthlyTotal * 36
        let fiveYearCost = monthlyTotal * 60

        // Equivalent months delay: how many months the subscriptions could pay off debt
        let monthsDelay: Int
        if extraPayment == 0 {
            monthsDelay = 0  // No extra payment, so no delay from subscriptions
        } else {
            let ratio = monthlyTotal / extraPayment
            monthsDelay = Int(ceil(NSDecimalNumber(decimal: ratio).doubleValue)) * payoffMonths
        }

        // Extra payment lost: subscriptions prevent using that money for debt
        let extraPaymentLost = monthlyTotal * Decimal(payoffMonths)

        return SubscriptionImpact(
            monthlyTotal: MoneyUtils.roundToTwoDecimals(monthlyTotal),
            threeYearCost: MoneyUtils.roundToTwoDecimals(threeYearCost),
            fiveYearCost: MoneyUtils.roundToTwoDecimals(fiveYearCost),
            monthsDelay: monthsDelay,
            extraPaymentLost: MoneyUtils.roundToTwoDecimals(extraPaymentLost)
        )
    }
}