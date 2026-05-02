import Foundation

struct SmartDefaultsEngine {
    static func inferDefaults(for debts: [Debt]) -> [Debt] {
        return debts.map { debt in
            var updated = debt
            if updated.annualInterestRate == nil {
                updated.annualInterestRate = defaultRate(for: updated.type)
            }
            if updated.minimumPayment == nil {
                updated.minimumPayment = defaultMinPayment(for: updated.balance)
            }
            return updated
        }
    }

    private static func defaultRate(for type: DebtType?) -> Decimal {
        switch type {
        case .creditCard: return 18
        case .loan: return 10
        case .mortgage: return 4
        case .other, nil: return 8
        }
    }

    private static func defaultMinPayment(for balance: Decimal) -> Decimal {
        return balance * 0.02 // 2% of balance
    }
}