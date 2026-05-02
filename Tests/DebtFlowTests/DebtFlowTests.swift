import Testing
import Foundation
@testable import DebtFlow

@Test func testAvalancheStrategy() async throws {
    let debts = [
        Debt(name: "High Rate", balance: 1000, annualInterestRate: 20, minimumPayment: 50, type: .creditCard),
        Debt(name: "Low Rate", balance: 1000, annualInterestRate: 10, minimumPayment: 50, type: .loan)
    ]
    let request = DebtPayoffRequest(debts: debts, extraMonthlyPayment: 0, strategy: .avalanche, subscriptions: nil)
    let result = PayoffEngine.calculate(request: request)
    
    #expect(result.totalMonths > 0)
    #expect(result.totalInterestPaid > 0)
    #expect(result.strategy == "avalanche")
    #expect(result.insights.count > 0)
}

@Test func testSnowballStrategy() async throws {
    let debts = [
        Debt(name: "Small Balance", balance: 500, annualInterestRate: 10, minimumPayment: 50, type: .loan),
        Debt(name: "Large Balance", balance: 1500, annualInterestRate: 10, minimumPayment: 50, type: .loan)
    ]
    let request = DebtPayoffRequest(debts: debts, extraMonthlyPayment: 0, strategy: .snowball, subscriptions: nil)
    let result = PayoffEngine.calculate(request: request)
    
    #expect(result.totalMonths > 0)
    #expect(result.totalInterestPaid > 0)
    #expect(result.strategy == "snowball")
    #expect(result.milestones.count > 0)
}

@Test func testMomentumStrategy() async throws {
    let debts = [
        Debt(name: "Small", balance: 500, annualInterestRate: 10, minimumPayment: 50, type: .loan),
        Debt(name: "High Rate", balance: 1000, annualInterestRate: 20, minimumPayment: 50, type: .creditCard)
    ]
    let request = DebtPayoffRequest(debts: debts, extraMonthlyPayment: 0, strategy: .momentum, subscriptions: nil)
    let result = PayoffEngine.calculate(request: request)
    
    #expect(result.totalMonths > 0)
    #expect(result.strategy == "momentum")
}

@Test func testSingleDebt() async throws {
    let debts = [Debt(name: "Only Debt", balance: 1000, annualInterestRate: 12, minimumPayment: 100, type: .loan)]
    let request = DebtPayoffRequest(debts: debts, extraMonthlyPayment: 50, strategy: .avalanche, subscriptions: nil)
    let result = PayoffEngine.calculate(request: request)
    
    #expect(result.totalMonths > 0)
    #expect(result.totalAmountPaid >= 1000)
}

@Test func testSmartDefaults() async throws {
    let debts = [
        Debt(name: "Credit Card", balance: 1000, annualInterestRate: nil, minimumPayment: nil, type: .creditCard),
        Debt(name: "Loan", balance: 2000, annualInterestRate: nil, minimumPayment: nil, type: .loan)
    ]
    let request = DebtPayoffRequest(debts: debts, extraMonthlyPayment: 0, strategy: .avalanche, subscriptions: nil)
    let result = PayoffEngine.calculate(request: request)
    
    #expect(result.totalMonths > 0)
    // Should infer rates: 18% for credit card, 10% for loan, min payments 2% of balance
}

@Test func testSubscriptionImpact() async throws {
    let debts = [Debt(name: "Debt", balance: 1000, annualInterestRate: 10, minimumPayment: 50, type: .loan)]
    let subscriptions = [Subscription(name: "Netflix", monthlyCost: 15)]
    let request = DebtPayoffRequest(debts: debts, extraMonthlyPayment: 50, strategy: .avalanche, subscriptions: subscriptions)
    let result = PayoffEngine.calculate(request: request)
    
    #expect(result.subscriptionImpact != nil)
    #expect(result.subscriptionImpact!.monthlyTotal == 15)
}

@Test func testValidationNoDebts() async throws {
    let request = DebtPayoffRequest(debts: [], extraMonthlyPayment: 0, strategy: .avalanche, subscriptions: nil)
    let result = PayoffEngine.calculate(request: request)
    
    #expect(result.totalMonths == 0)
    #expect(result.warnings.contains(where: { $0.contains("No debts provided") }))
}

@Test func testValidationNegativeBalance() async throws {
    let debts = [Debt(name: "Bad", balance: -100, annualInterestRate: 10, minimumPayment: 50, type: .loan)]
    let request = DebtPayoffRequest(debts: debts, extraMonthlyPayment: 0, strategy: .avalanche, subscriptions: nil)
    let result = PayoffEngine.calculate(request: request)
    
    #expect(result.totalMonths == 0)
    #expect(result.warnings.contains(where: { $0.contains("invalid balance") }))
}

@Test func testValidationNegativeRate() async throws {
    let debts = [Debt(name: "Bad", balance: 1000, annualInterestRate: -5, minimumPayment: 50, type: .loan)]
    let request = DebtPayoffRequest(debts: debts, extraMonthlyPayment: 0, strategy: .avalanche, subscriptions: nil)
    let result = PayoffEngine.calculate(request: request)
    
    #expect(result.totalMonths == 0)
    #expect(result.warnings.contains(where: { $0.contains("negative interest rate") }))
}

@Test func testValidationZeroMinPayment() async throws {
    let debts = [Debt(name: "Bad", balance: 1000, annualInterestRate: 10, minimumPayment: 0, type: .loan)]
    let request = DebtPayoffRequest(debts: debts, extraMonthlyPayment: 0, strategy: .avalanche, subscriptions: nil)
    let result = PayoffEngine.calculate(request: request)
    
    #expect(result.totalMonths == 0)
    #expect(result.warnings.contains(where: { $0.contains("invalid minimum payment") }))
}

@Test func testValidationNegativeExtra() async throws {
    let debts = [Debt(name: "Good", balance: 1000, annualInterestRate: 10, minimumPayment: 50, type: .loan)]
    let request = DebtPayoffRequest(debts: debts, extraMonthlyPayment: -10, strategy: .avalanche, subscriptions: nil)
    let result = PayoffEngine.calculate(request: request)
    
    #expect(result.totalMonths == 0)
    #expect(result.warnings.contains(where: { $0.contains("negative") }))
}

@Test func testJSONEncodingDecoding() async throws {
    let request = DebtPayoffRequest(
        debts: [Debt(name: "Test", balance: 1000, annualInterestRate: 10, minimumPayment: 50, type: .loan)],
        extraMonthlyPayment: 25,
        strategy: .avalanche,
        subscriptions: [Subscription(name: "Test Sub", monthlyCost: 10)]
    )
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    let data = try encoder.encode(request)
    let decoded = try decoder.decode(DebtPayoffRequest.self, from: data)
    
    #expect(decoded.debts.count == 1)
    #expect(decoded.subscriptions?.count == 1)
    #expect(decoded.debts[0].name == "Test")
    #expect(decoded.extraMonthlyPayment == 25)
    #expect(decoded.strategy == .avalanche)
}

@Test func testPayoffResultEncoding() async throws {
    let result = PayoffResult(
        strategy: "avalanche",
        totalMonths: 12,
        totalInterestPaid: 100,
        totalAmountPaid: 1100,
        freedomDate: "January 1, 2025",
        monthlySummary: [],
        summary: "Test summary",
        insights: ["Test insight"],
        warnings: [],
        milestones: ["Test milestone"],
        subscriptionImpact: nil
    )
    
    let encoder = JSONEncoder()
    let data = try encoder.encode(result)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(PayoffResult.self, from: data)
    
    #expect(decoded.totalMonths == 12)
    #expect(decoded.totalInterestPaid == 100)
    #expect(decoded.insights == ["Test insight"])
}
