import Foundation

struct PayoffEngine {

    static func calculate(request: DebtPayoffRequest) -> PayoffResult {
        // Infer defaults
        let debtsWithDefaults = SmartDefaultsEngine.inferDefaults(for: request.debts)

        // Validation
        guard !debtsWithDefaults.isEmpty else {
            return PayoffResult(
                strategy: request.strategy.rawValue,
                totalMonths: 0,
                totalInterestPaid: 0,
                totalAmountPaid: 0,
                freedomDate: "N/A",
                monthlySummary: [],
                summary: "Error: No debts provided.",
                insights: [],
                warnings: ["No debts provided."],
                milestones: [],
                subscriptionImpact: nil
            )
        }

        var warnings: [String] = []
        for debt in debtsWithDefaults {
            if debt.balance <= 0 {
                warnings.append("Debt '\(debt.name)' has invalid balance.")
            }
            if debt.annualInterestRate ?? 0 < 0 {
                warnings.append("Debt '\(debt.name)' has negative interest rate.")
            }
            if debt.minimumPayment ?? 0 <= 0 {
                warnings.append("Debt '\(debt.name)' has invalid minimum payment.")
            }
        }
        if request.extraMonthlyPayment < 0 {
            warnings.append("Extra payment cannot be negative.")
        }

        if !warnings.isEmpty {
            return PayoffResult(
                strategy: request.strategy.rawValue,
                totalMonths: 0,
                totalInterestPaid: 0,
                totalAmountPaid: 0,
                freedomDate: "N/A",
                monthlySummary: [],
                summary: "Validation errors found.",
                insights: [],
                warnings: warnings,
                milestones: [],
                subscriptionImpact: nil
            )
        }

        var debts = debtsWithDefaults.map { debt in
            (name: debt.name,
             balance: debt.balance,
             rate: debt.monthlyInterestRate,
             minPayment: debt.minimumPayment!)
        }

        // Sort based on strategy
        switch request.strategy {
        case .avalanche:
            debts.sort { $0.rate > $1.rate }
        case .snowball:
            debts.sort { $0.balance < $1.balance }
        case .momentum:
            // Start snowball, switch after first payoff
            debts.sort { $0.balance < $1.balance }
        }

        var snapshots: [MonthlySnapshot] = []
        var totalInterest: Decimal = 0
        var totalPaid: Decimal = 0
        var month = 0
        let maxMonths = 600
        var firstDebtCleared = false
        var halfProgressMonth = 0
        let totalOriginalBalance: Decimal = debts.reduce(0) { $0 + $1.balance }

        while debts.contains(where: { $0.balance > 0.01 }) && month < maxMonths {
            month += 1
            var extraRemaining = request.extraMonthlyPayment

            // Check for momentum switch
            if request.strategy == .momentum && !firstDebtCleared && debts.filter({ $0.balance <= 0.01 }).count > 0 {
                firstDebtCleared = true
                // Switch to avalanche
                debts = debts.filter { $0.balance > 0.01 }.sorted { $0.rate > $1.rate } + debts.filter { $0.balance <= 0.01 }
            }

            for i in 0..<debts.count {
                guard debts[i].balance > 0.01 else { continue }

                let interest = debts[i].balance * debts[i].rate
                totalInterest += interest

                var payment = debts[i].minPayment
                if i == debts.firstIndex(where: { $0.balance > 0.01 }) {
                    payment += extraRemaining
                    extraRemaining = 0
                }

                payment = min(payment, debts[i].balance + interest)
                let principal = payment - interest
                debts[i].balance = max(0, debts[i].balance - principal)
                totalPaid += payment

                snapshots.append(MonthlySnapshot(
                    month: month,
                    debtName: debts[i].name,
                    remainingBalance: MoneyUtils.roundToTwoDecimals(debts[i].balance),
                    interestPaid: MoneyUtils.roundToTwoDecimals(interest),
                    principalPaid: MoneyUtils.roundToTwoDecimals(principal)
                ))
            }

            // Track milestones
            let currentPaidOff = totalOriginalBalance - debts.reduce(0) { $0 + $1.balance }
            if halfProgressMonth == 0 && currentPaidOff >= totalOriginalBalance / 2 {
                halfProgressMonth = month
            }
        }

        // Detect infinite payoff
        if month >= maxMonths {
            warnings.append("Payoff may take longer than 50 years. Consider increasing payments or seeking professional advice.")
        }

        let freedomDate = DateUtils.freedomDate(from: month)

        // Subscription impact
        let subscriptionImpact = request.subscriptions.map {
            SubscriptionImpactEngine.calculateImpact(subscriptions: $0, extraPayment: request.extraMonthlyPayment, payoffMonths: month, totalInterest: totalInterest)
        }

        // Milestones
        var milestones: [String] = []
        if let firstClearedMonth = snapshots.first(where: { $0.remainingBalance <= 0 })?.month {
            milestones.append("First debt cleared in \(DateUtils.monthsToYearsMonths(firstClearedMonth))")
        }
        if halfProgressMonth > 0 {
            milestones.append("50% progress in \(DateUtils.monthsToYearsMonths(halfProgressMonth))")
        }
        milestones.append("Debt-free in \(DateUtils.monthsToYearsMonths(month))")

        // Summary
        let summary = "Payoff in \(DateUtils.monthsToYearsMonths(month)), total paid \(MoneyUtils.format(totalPaid)), interest \(MoneyUtils.format(totalInterest))"

        // Insights
        let insights = InsightEngine.generateInsights(result: PayoffResult(strategy: request.strategy.rawValue, totalMonths: month, totalInterestPaid: totalInterest, totalAmountPaid: totalPaid, freedomDate: freedomDate, monthlySummary: snapshots, summary: summary, insights: [], warnings: warnings, milestones: milestones, subscriptionImpact: subscriptionImpact), subscriptions: request.subscriptions, originalDebts: debtsWithDefaults)

        return PayoffResult(
            strategy: request.strategy.rawValue,
            totalMonths: month,
            totalInterestPaid: MoneyUtils.roundToTwoDecimals(totalInterest),
            totalAmountPaid: MoneyUtils.roundToTwoDecimals(totalPaid),
            freedomDate: freedomDate,
            monthlySummary: snapshots,
            summary: summary,
            insights: insights,
            warnings: warnings,
            milestones: milestones,
            subscriptionImpact: subscriptionImpact
        )
    }
}