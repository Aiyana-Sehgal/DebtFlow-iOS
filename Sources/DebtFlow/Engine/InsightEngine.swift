import Foundation

struct InsightEngine {
    static func generateInsights(result: PayoffResult, subscriptions: [Subscription]?, originalDebts: [Debt]) -> [String] {
        var insights: [String] = []

        // Motivational insights
        if result.totalMonths < 12 {
            insights.append("You're on track to be debt-free in just \(DateUtils.monthsToYearsMonths(result.totalMonths))! Incredible discipline.")
        } else if result.totalMonths < 60 {
            insights.append("You'll gain \(DateUtils.monthsToYearsMonths(result.totalMonths)) of financial freedom. Every month counts.")
        } else {
            insights.append("This plan saves you \(MoneyUtils.format(result.totalInterestPaid)) in interest over \(DateUtils.monthsToYearsMonths(result.totalMonths)). Stay committed.")
        }

        // Subscription insights
        if let subs = subscriptions, !subs.isEmpty, let impact = result.subscriptionImpact {
            insights.append("Your subscriptions cost \(MoneyUtils.format(impact.monthlyTotal)) monthly, equivalent to \(impact.monthsDelay) months delay in debt payoff.")
            if impact.monthlyTotal > result.totalAmountPaid / Decimal(result.totalMonths) {
                insights.append("Subscriptions are costing you more than your debt payments. Consider reviewing your recurring expenses.")
            }
        }

        // Behavioral nudges
        if result.strategy == "avalanche" {
            insights.append("Focusing on high-interest debts first maximizes savings. You're building long-term wealth.")
        } else if result.strategy == "snowball" {
            insights.append("Paying smallest debts first builds momentum. Quick wins fuel motivation!")
        } else {
            insights.append("Momentum strategy combines the best of both worlds. Smart choice!")
        }

        // Age milestone if possible (assume current age, but since no input, skip or generic)
        // For now, generic
        insights.append("Small consistent actions now create big freedom later. You're investing in your future self.")

        return insights
    }
}