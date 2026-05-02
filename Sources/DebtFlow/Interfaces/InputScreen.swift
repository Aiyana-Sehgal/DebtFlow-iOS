import SwiftUI

struct InputScreen: View {
    @Bindable var viewModel: DebtFlowViewModel
    var onCalculate: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // Header
                VStack(spacing: 12) {
                    Text("Your Path to Freedom")
                        .font(AntigravityTheme.titleFont())
                        .foregroundColor(AntigravityTheme.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("Let's visualize your financial reality with calmness.")
                        .font(AntigravityTheme.bodyFont())
                        .foregroundColor(AntigravityTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)
                
                // Input Fields
                VStack(spacing: 24) {
                    // Debt Amount
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total Debt")
                            .font(AntigravityTheme.captionFont())
                            .foregroundColor(AntigravityTheme.textTertiary)
                            .padding(.leading, 4)
                        
                        TextField("₹0.00", text: $viewModel.debtAmount)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .padding(24)
                            .background(AntigravityTheme.cardBackground)
                            .cornerRadius(AntigravityTheme.cornerRadiusMedium)
                    }
                    
                    // Debt Type
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Debt Type")
                            .font(AntigravityTheme.captionFont())
                            .foregroundColor(AntigravityTheme.textTertiary)
                            .padding(.leading, 4)
                        
                        Picker("Type", selection: $viewModel.debtType) {
                            Text("Credit Card").tag(DebtType.creditCard)
                            Text("Loan").tag(DebtType.loan)
                            Text("Mortgage").tag(DebtType.mortgage)
                            Text("Other").tag(DebtType.other)
                        }
                        .pickerStyle(.segmented)
                        .padding(8)
                        .background(AntigravityTheme.cardBackground)
                        .cornerRadius(AntigravityTheme.cornerRadiusMedium)
                    }
                    
                    // Subscription Estimate
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Monthly Subscriptions (Optional)")
                            .font(AntigravityTheme.captionFont())
                            .foregroundColor(AntigravityTheme.textTertiary)
                            .padding(.leading, 4)
                        
                        TextField("₹1,200", text: $viewModel.monthlySubscriptionEstimate)
                            .font(AntigravityTheme.bodyFont())
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .padding(20)
                            .background(AntigravityTheme.cardBackground)
                            .cornerRadius(AntigravityTheme.cornerRadiusMedium)
                    }
                }
                .padding(.horizontal, 24)
                
                // CTA Button
                Button(action: onCalculate) {
                    HStack {
                        Text("See My Reality")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        
                        if viewModel.isCalculating {
                            ProgressView()
                                .tint(.white)
                                .padding(.leading, 8)
                        } else {
                            Image(systemName: "sparkles")
                                .padding(.leading, 4)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(AntigravityTheme.accentGradient)
                    .cornerRadius(AntigravityTheme.cornerRadiusMedium)
                    .shadow(color: Color.blue.opacity(0.2), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .disabled(viewModel.debtAmount.isEmpty || viewModel.isCalculating)
                
                Spacer()
            }
        }
    }
}

struct InputScreen_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AntigravityTheme.backgroundGradient.ignoresSafeArea()
            InputScreen(viewModel: DebtFlowViewModel(), onCalculate: {})
        }
    }
}
