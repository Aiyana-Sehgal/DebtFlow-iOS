import SwiftUI
import Observation
import os

@Observable
class DebtFlowViewModel {
    // MARK: - Internal Logger
    // Enforcing Zero Analytics Policy by using local OSLog only
    private let logger = Logger(subsystem: "com.debtflow.app", category: "CoreEngine")
    
    // MARK: - Security State
    var isIncognitoMode: Bool = true // Defaulting to true for absolute privacy
    
    // MARK: - Input State
    var debtAmount: String = ""
    var debtType: DebtType = .creditCard
    var monthlySubscriptionEstimate: String = ""
    
    // MARK: - App State
    var isCalculating: Bool = false
    var currentResult: PayoffResult?
    var selectedStrategy: Strategy = .avalanche
    
    // MARK: - Actions
    func calculateReality() {
        isCalculating = true
        logger.info("Starting calculation. Incognito mode: \(self.isIncognitoMode)")
        
        // Simulate network delay for "organic" feel
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.currentResult = MockData.samplePayoffResult
            self.isCalculating = false
            self.logger.info("Calculation complete. Zero data persisted.")
        }
    }
    
    func toggleStrategy() {
        withAnimation(.easeInOut) {
            if selectedStrategy == .avalanche {
                selectedStrategy = .snowball
                currentResult = MockData.sampleSnowballResult
            } else {
                selectedStrategy = .avalanche
                currentResult = MockData.samplePayoffResult
            }
            logger.debug("Strategy toggled to \(String(describing: self.selectedStrategy))")
        }
    }
    
    func resetSession() {
        logger.info("Wiping session data (Incognito trigger / App Background)")
        debtAmount = ""
        monthlySubscriptionEstimate = ""
        currentResult = nil
        isCalculating = false
    }
    
    // MARK: - Helpers
    var heroInsight: String {
        guard let result = currentResult else { return "" }
        if result.totalMonths < 12 {
            return "You're debt-free in just \(result.totalMonths) months"
        } else {
            let years = result.totalMonths / 12
            return "You're debt-free in \(years) years"
        }
    }
    
    var formattedInterest: String {
        guard let result = currentResult else { return "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR" // Based on user request snippets like ₹38,000
        return formatter.string(from: result.totalInterestPaid as NSDecimalNumber) ?? "₹0"
    }
}
