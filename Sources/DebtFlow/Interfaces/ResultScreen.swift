import SwiftUI

struct ResultScreen: View {
    @Bindable var viewModel: DebtFlowViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            AntigravityTheme.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Hero Insight
                    VStack(spacing: 12) {
                        Text(viewModel.heroInsight)
                            .font(AntigravityTheme.titleFont())
                            .foregroundColor(AntigravityTheme.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                        
                        Text("This is your path to financial weightlessness.")
                            .font(AntigravityTheme.bodyFont())
                            .foregroundColor(AntigravityTheme.textSecondary)
                    }
                    .padding(.top, 40)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    
                    // Strategy Toggle
                    HStack(spacing: 0) {
                        strategyButton(title: "Avalanche", strategy: .avalanche)
                        strategyButton(title: "Snowball", strategy: .snowball)
                    }
                    .padding(4)
                    .background(AntigravityTheme.glassBackground)
                    .cornerRadius(AntigravityTheme.cornerRadiusMedium)
                    .padding(.horizontal, 24)
                    
                    // Summary Card
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Label("Summary", systemImage: "chart.bar.fill")
                                .font(AntigravityTheme.captionFont())
                                .foregroundColor(AntigravityTheme.textTertiary)
                            Spacer()
                        }
                        
                        HStack(spacing: 24) {
                            summaryStat(label: "Interest", value: viewModel.formattedInterest)
                            summaryStat(label: "Duration", value: "\(viewModel.currentResult?.totalMonths ?? 0) mos")
                            summaryStat(label: "Freedom", value: viewModel.currentResult?.freedomDate ?? "--")
                        }
                    }
                    .antigravityCard()
                    .padding(.horizontal, 24)
                    
                    // Subscription Impact Card (if exists)
                    if let impact = viewModel.currentResult?.subscriptionImpact {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Label("Hidden Drain", systemImage: "timer")
                                    .font(AntigravityTheme.captionFont())
                                    .foregroundColor(.orange)
                                Spacer()
                            }
                            
                            Text("Your subscriptions are delaying you by \(impact.monthsDelay) months.")
                                .font(AntigravityTheme.bodyFont())
                                .foregroundColor(AntigravityTheme.textPrimary)
                            
                            Text("Redirecting these could save you ₹\(Int(truncating: impact.extraPaymentLost as NSDecimalNumber)) in the long run.")
                                .font(AntigravityTheme.captionFont())
                                .foregroundColor(AntigravityTheme.textSecondary)
                        }
                        .antigravityCard()
                        .padding(.horizontal, 24)
                    }
                    
                    // Milestones Section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Your Milestones")
                            .font(AntigravityTheme.headlineFont())
                            .foregroundColor(AntigravityTheme.textPrimary)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(viewModel.currentResult?.milestones ?? [], id: \.self) { milestone in
                                HStack(spacing: 16) {
                                    Circle()
                                        .fill(AntigravityTheme.accentGradient)
                                        .frame(width: 10, height: 10)
                                    
                                    Text(milestone)
                                        .font(AntigravityTheme.bodyFont())
                                        .foregroundColor(AntigravityTheme.textSecondary)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 32)
                    
                    // Insights Section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Insights")
                            .font(AntigravityTheme.headlineFont())
                            .foregroundColor(AntigravityTheme.textPrimary)
                        
                        ForEach(viewModel.currentResult?.insights ?? [], id: \.self) { insight in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 14))
                                    .padding(.top, 2)
                                
                                Text(insight)
                                    .font(AntigravityTheme.bodyFont())
                                    .foregroundColor(AntigravityTheme.textSecondary)
                                    .lineSpacing(4)
                            }
                            .padding(.bottom, 8)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 32)
                    
                    // Back Button
                    Button(action: { dismiss() }) {
                        Text("Back to Reality")
                            .font(AntigravityTheme.bodyFont())
                            .foregroundColor(AntigravityTheme.textSecondary)
                            .padding(.vertical, 16)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    // MARK: - Components
    
    private func strategyButton(title: String, strategy: Strategy) -> some View {
        Button(action: { viewModel.toggleStrategy() }) {
            Text(title)
                .font(AntigravityTheme.captionFont().weight(.bold))
                .foregroundColor(viewModel.selectedStrategy == strategy ? .white : AntigravityTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    viewModel.selectedStrategy == strategy ? 
                    AntigravityTheme.accentGradient : 
                    LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(AntigravityTheme.cornerRadiusMedium - 4)
        }
        .animation(.spring(), value: viewModel.selectedStrategy)
    }
    
    private func summaryStat(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AntigravityTheme.captionFont())
                .foregroundColor(AntigravityTheme.textTertiary)
            Text(value)
                .font(AntigravityTheme.bodyFont().weight(.bold))
                .foregroundColor(AntigravityTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ResultScreen_Previews: PreviewProvider {
    static var previews: some View {
        ResultScreen(viewModel: {
            let vm = DebtFlowViewModel()
            vm.currentResult = MockData.samplePayoffResult
            return vm
        }())
    }
}
