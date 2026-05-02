import Foundation

enum Strategy: String, Codable {
    case avalanche
    case snowball
    case momentum
}

enum DebtType: String, Codable {
    case creditCard = "credit_card"
    case loan = "loan"
    case mortgage = "mortgage"
    case other = "other"
}

struct Debt: Codable {
    let name: String
    let balance: Decimal
    var annualInterestRate: Decimal?
    var minimumPayment: Decimal?
    let type: DebtType?

    var monthlyInterestRate: Decimal {
        return (annualInterestRate ?? 0) / 100 / 12
    }
}

struct Subscription: Codable {
    let name: String
    let monthlyCost: Decimal
}

struct DebtPayoffRequest: Codable {
    let debts: [Debt]
    let extraMonthlyPayment: Decimal
    let strategy: Strategy
    let subscriptions: [Subscription]?
}

struct SubscriptionImpact: Codable {
    let monthlyTotal: Decimal
    let threeYearCost: Decimal
    let fiveYearCost: Decimal
    let monthsDelay: Int
    let extraPaymentLost: Decimal
}

struct MonthlySnapshot: Codable {
    let month: Int
    let debtName: String
    let remainingBalance: Decimal
    let interestPaid: Decimal
    let principalPaid: Decimal
}

struct PayoffResult: Codable {
    let strategy: String
    let totalMonths: Int
    let totalInterestPaid: Decimal
    let totalAmountPaid: Decimal
    let freedomDate: String
    let monthlySummary: [MonthlySnapshot]
    let summary: String
    let insights: [String]
    let warnings: [String]
    let milestones: [String]
    let subscriptionImpact: SubscriptionImpact?
}