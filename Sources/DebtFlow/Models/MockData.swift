import Foundation

struct MockData {
    static let samplePayoffResult = PayoffResult(
        strategy: "Avalanche",
        totalMonths: 36,
        totalInterestPaid: 12450.50,
        totalAmountPaid: 54950.50,
        freedomDate: "May 2027",
        monthlySummary: [],
        summary: "You are on track to be debt-free in 3 years.",
        insights: [
            "You're gaining nearly a year back by optimizing your payments.",
            "Your interest rate is averaging 18%, which we've mitigated by ₹38,000.",
            "Small changes today are giving you 11 months of freedom."
        ],
        warnings: [
            "Missing minimum payment on one card could delay you by 3 months."
        ],
        milestones: [
            "First debt cleared: October 2024",
            "Halfway point: March 2026",
            "Final freedom: May 2027"
        ],
        subscriptionImpact: SubscriptionImpact(
            monthlyTotal: 85.00,
            threeYearCost: 3060.00,
            fiveYearCost: 5100.00,
            monthsDelay: 5,
            extraPaymentLost: 4250.00
        )
    )
    
    static let sampleSnowballResult = PayoffResult(
        strategy: "Snowball",
        totalMonths: 41,
        totalInterestPaid: 15600.20,
        totalAmountPaid: 58100.20,
        freedomDate: "October 2027",
        monthlySummary: [],
        summary: "Snowball method focuses on small wins first.",
        insights: [
            "You'll clear your first small debt in just 4 months.",
            "Total interest is slightly higher, but psychological momentum is key."
        ],
        warnings: [],
        milestones: [
            "First debt cleared: August 2024",
            "Final freedom: October 2027"
        ],
        subscriptionImpact: nil
    )
}
