import Foundation

func runCLI() {
    print("=================================")
    print("  DebtFlow — Debt Payoff Engine  ")
    print("=================================\n")

    var debts: [Debt] = []
    var subscriptions: [Subscription] = []

    print("Enter your debts (press Enter without input to finish):")
    while true {
        print("Debt name (or empty to finish): ", terminator: "")
        guard let name = readLine(), !name.isEmpty else { break }

        print("Balance: ", terminator: "")
        guard let balanceStr = readLine(), let balance = Decimal(string: balanceStr), balance > 0 else {
            print("Invalid balance. Must be a positive number.")
            continue
        }

        print("Type (credit_card, loan, mortgage, other) [optional]: ", terminator: "")
        let typeStr = readLine()
        let type = typeStr?.isEmpty == false ? DebtType(rawValue: typeStr!) : nil

        print("Annual interest rate (%) [optional]: ", terminator: "")
        let rateStr = readLine()
        let rate = rateStr?.isEmpty == false ? Decimal(string: rateStr!) : nil

        print("Minimum monthly payment [optional]: ", terminator: "")
        let minStr = readLine()
        let minPayment = minStr?.isEmpty == false ? Decimal(string: minStr!) : nil

        debts.append(Debt(name: name, balance: balance, annualInterestRate: rate, minimumPayment: minPayment, type: type))
        print("Debt added.\n")
    }

    print("Enter your subscriptions (press Enter without input to finish):")
    while true {
        print("Subscription name (or empty to finish): ", terminator: "")
        guard let name = readLine(), !name.isEmpty else { break }

        print("Monthly cost: ", terminator: "")
        guard let costStr = readLine(), let cost = Decimal(string: costStr), cost > 0 else {
            print("Invalid cost. Must be a positive number.")
            continue
        }

        subscriptions.append(Subscription(name: name, monthlyCost: cost))
        print("Subscription added.\n")
    }

    if debts.isEmpty {
        print("No debts entered. Exiting.")
        return
    }

    var extra: Decimal?
    while extra == nil {
        print("Extra monthly payment: ", terminator: "")
        if let extraStr = readLine(), let parsed = Decimal(string: extraStr), parsed >= 0 {
            extra = parsed
        } else {
            print("Invalid extra payment. Must be a non-negative number.")
        }
    }

    var strategy: Strategy?
    while strategy == nil {
        print("Strategy (avalanche, snowball, momentum): ", terminator: "")
        if let stratStr = readLine()?.lowercased() {
            strategy = Strategy(rawValue: stratStr)
            if strategy == nil {
                print("Invalid strategy. Choose 'avalanche', 'snowball', or 'momentum'.")
            }
        }
    }

    print("\nYour debts:")
    for debt in debts {
        let rateStr = debt.annualInterestRate != nil ? "\(debt.annualInterestRate!)%" : "estimated"
        let minPaymentStr = debt.minimumPayment != nil ? MoneyUtils.format(debt.minimumPayment!) : "estimated"
        print("  • \(debt.name): \(MoneyUtils.format(debt.balance)) @ \(rateStr) APR, min \(minPaymentStr)")
    }
    if !subscriptions.isEmpty {
        print("\nYour subscriptions:")
        for sub in subscriptions {
            print("  • \(sub.name): \(MoneyUtils.format(sub.monthlyCost)) monthly")
        }
    }
    print("\nExtra monthly payment: \(MoneyUtils.format(extra!))")
    print("Strategy: \(strategy!.rawValue.uppercased())\n")

    let request = DebtPayoffRequest(
        debts: debts,
        extraMonthlyPayment: extra!,
        strategy: strategy!,
        subscriptions: subscriptions.isEmpty ? nil : subscriptions
    )

    let result = PayoffEngine.calculate(request: request)

    print("RESULTS")
    print("-------")
    print("Freedom Date:        \(result.freedomDate)")
    print("Total Months:        \(result.totalMonths) (\(result.totalMonths / 12) yrs \(result.totalMonths % 12) mo)")
    print("Total Interest Paid: \(MoneyUtils.format(result.totalInterestPaid))")
    print("Total Amount Paid:   \(MoneyUtils.format(result.totalAmountPaid))")
    print("\nSummary: \(result.summary)")

    if !result.insights.isEmpty {
        print("\nInsights:")
        for insight in result.insights {
            print("  • \(insight)")
        }
    }

    if !result.warnings.isEmpty {
        print("\nWarnings:")
        for warning in result.warnings {
            print("  ⚠️ \(warning)")
        }
    }

    if !result.milestones.isEmpty {
        print("\nMilestones:")
        for milestone in result.milestones {
            print("  🏆 \(milestone)")
        }
    }

    if let impact = result.subscriptionImpact {
        print("\nSubscription Impact:")
        print("  Monthly Total: \(MoneyUtils.format(impact.monthlyTotal))")
        print("  3-Year Cost: \(MoneyUtils.format(impact.threeYearCost))")
        print("  5-Year Cost: \(MoneyUtils.format(impact.fiveYearCost))")
        print("  Months Delay: \(impact.monthsDelay)")
        print("  Extra Payment Lost: \(MoneyUtils.format(impact.extraPaymentLost))")
    }
}

func launchBackend() {
    if CommandLine.arguments.contains("cli") {
        runCLI()
    } else {
        startServer(port: 8080)
    }
}