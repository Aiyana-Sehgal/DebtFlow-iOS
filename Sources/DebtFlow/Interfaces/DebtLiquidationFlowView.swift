import SwiftUI

// MARK: - Color Theme
struct AppTheme {
    // Backgrounds - Matte Charcoal / Deep Slate Grey (No Blue)
    static let background = Color(white: 0.12)
    static let surface = Color(white: 0.18)
    static let surfaceElevated = Color(white: 0.25)
    
    // Gradients - Lava Inspired
    static let brightRed = Color(red: 1.0, green: 0.2, blue: 0.2) // Coral/Red
    static let orangeYellow = Color(red: 1.0, green: 0.6, blue: 0.0) // Tangerine
    static let deepViolet = Color(red: 0.6, green: 0.1, blue: 0.6) // Magenta/Violet
    
    static let lavaGradient = LinearGradient(
        colors: [brightRed, orangeYellow],
        startPoint: .bottomLeading,
        endPoint: .topTrailing
    )
    
    static let secondaryLavaGradient = LinearGradient(
        colors: [deepViolet, brightRed],
        startPoint: .bottomLeading,
        endPoint: .topTrailing
    )
    
    // Text Colors
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.65)
    static let textTertiary = Color(white: 0.45)
    
    // Borders
    static let border = Color(white: 0.3)
}

// MARK: - Main View
struct DebtLiquidationFlowView: View {
    @State private var isPressed = false
    
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 32) {
                    // Header
                    headerSection
                    
                    // Main Progress
                    progressSection
                    
                    // Data Table / Bento Grid
                    statsBentoGrid
                    
                    // Subscription Drain Analysis
                    subscriptionAnalysisSection
                    
                    // Debt Recovery Strategy
                    recoveryStrategySection
                    
                    // Milestones Feed
                    milestonesSection
                    
                    // Action Button
                    actionButton
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("DEBT LIQUIDATION")
                    .font(.system(size: 13, weight: .black, design: .default))
                    .tracking(2)
                    .foregroundColor(AppTheme.textSecondary)
                
                Text("Active Flow")
                    .font(.system(size: 34, weight: .bold, design: .default))
                    .foregroundColor(AppTheme.textPrimary)
            }
            Spacer()
            
            // Profile / Settings icon placeholder
            Circle()
                .fill(AppTheme.surfaceElevated)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(AppTheme.textPrimary)
                )
        }
        .padding(.top, 20)
    }
    
    // MARK: - Progress Ring
    private var progressSection: some View {
        VStack(spacing: 24) {
            ZStack {
                // Background Ring
                Circle()
                    .stroke(AppTheme.surfaceElevated, lineWidth: 28)
                    .frame(width: 240, height: 240)
                
                // Progress Ring
                Circle()
                    .trim(from: 0, to: 0.68)
                    .stroke(AppTheme.lavaGradient, style: StrokeStyle(lineWidth: 28, lineCap: .round))
                    .frame(width: 240, height: 240)
                    .rotationEffect(.degrees(-90))
                
                // Inner Content
                VStack(spacing: 8) {
                    Text("68%")
                        .font(.system(size: 56, weight: .heavy, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text("LIQUIDATED")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            
            // Total amount
            VStack(spacing: 4) {
                Text("$42,500")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Text("Remaining Balance")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(.vertical, 10)
    }
    
    // MARK: - Bento Grid Stats
    private var statsBentoGrid: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                statCard(
                    title: "NEXT PAYMENT",
                    value: "$1,250",
                    subtitle: "Due in 4 days",
                    gradient: AppTheme.secondaryLavaGradient
                )
                
                statCard(
                    title: "INTEREST SAVED",
                    value: "$8,420",
                    subtitle: "This year",
                    gradient: AppTheme.lavaGradient
                )
            }
            
            // Complex Data Table row
            dataTableCard
        }
    }
    
    private func statCard(title: String, value: String, subtitle: String, gradient: LinearGradient) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .tracking(1)
                .foregroundColor(AppTheme.textSecondary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(gradient)
                
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(AppTheme.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.border, lineWidth: 0.5)
        )
    }
    
    private var dataTableCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ALLOCATION BREAKDOWN")
                .font(.system(size: 11, weight: .bold))
                .tracking(1)
                .foregroundColor(AppTheme.textSecondary)
            
            VStack(spacing: 12) {
                dataTableRow(label: "Principal", amount: "$950.00", percentage: "76%")
                Divider().background(AppTheme.border)
                dataTableRow(label: "Interest", amount: "$300.00", percentage: "24%")
            }
        }
        .padding(20)
        .background(AppTheme.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.border, lineWidth: 0.5)
        )
    }
    
    private func dataTableRow(label: String, amount: String, percentage: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppTheme.textPrimary)
            
            Spacer()
            
            HStack(spacing: 16) {
                Text(percentage)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(width: 40, alignment: .trailing)
                
                Text(amount)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .frame(width: 80, alignment: .trailing)
            }
        }
    }
    
    // MARK: - Milestones Feed
    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("FINANCIAL MILESTONES")
                .font(.system(size: 13, weight: .bold))
                .tracking(1.5)
                .foregroundColor(AppTheme.textSecondary)
            
            VStack(spacing: 0) {
                milestoneRow(
                    icon: "checkmark.seal.fill",
                    title: "Student Loan Cleared",
                    date: "Oct 12",
                    amount: "-$12,400",
                    isCompleted: true,
                    isLast: false
                )
                
                milestoneRow(
                    icon: "flame.fill",
                    title: "Auto Loan Accelerated",
                    date: "Nov 01",
                    amount: "-$850/mo",
                    isCompleted: true,
                    isLast: false
                )
                
                milestoneRow(
                    icon: "target",
                    title: "Credit Card Freedom",
                    date: "Dec 15 (Proj.)",
                    amount: "$4,200",
                    isCompleted: false,
                    isLast: true
                )
            }
            .padding(.vertical, 8)
            .background(AppTheme.surface)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.border, lineWidth: 0.5)
            )
        }
    }
    
    private func milestoneRow(icon: String, title: String, date: String, amount: String, isCompleted: Bool, isLast: Bool) -> some View {
        HStack(spacing: 16) {
            // Timeline line & icon
            VStack(spacing: 0) {
                Circle()
                    .fill(isCompleted ? AppTheme.brightRed : AppTheme.surfaceElevated)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(isCompleted ? .white : AppTheme.textSecondary)
                    )
                    .zIndex(1)
                
                if !isLast {
                    Rectangle()
                        .fill(AppTheme.surfaceElevated)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .padding(.top, 4)
                }
            }
            .frame(width: 32)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isCompleted ? AppTheme.textPrimary : AppTheme.textSecondary)
                
                Text(date)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textTertiary)
            }
            
            Spacer()
            
            Text(amount)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(isCompleted ? AppTheme.textPrimary : AppTheme.textSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Action Button
    private var actionButton: some View {
        Button(action: {
            // Action logic
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isPressed = false
                }
            }
        }) {
            HStack(spacing: 12) {
                Text("EXECUTE PAYMENT")
                    .font(.system(size: 15, weight: .heavy, design: .default))
                    .tracking(1)
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.lavaGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: AppTheme.brightRed.opacity(isPressed ? 0.2 : 0.4), radius: isPressed ? 4 : 12, x: 0, y: isPressed ? 2 : 6)
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.top, 16)
    }
    
    // MARK: - Subscription Analysis
    private var subscriptionAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SUBSCRIPTION LEAKAGE")
                .font(.system(size: 13, weight: .bold))
                .tracking(1.5)
                .foregroundColor(AppTheme.textSecondary)
            
            VStack(spacing: 0) {
                subscriptionRow(name: "Premium Streaming", amount: "$19.99/mo", status: "High Drain", isDraining: true)
                Divider().background(AppTheme.border).padding(.leading, 60)
                subscriptionRow(name: "Fitness App", amount: "$12.99/mo", status: "Unused (3 mos)", isDraining: true)
                Divider().background(AppTheme.border).padding(.leading, 60)
                subscriptionRow(name: "Cloud Storage", amount: "$2.99/mo", status: "Active", isDraining: false)
            }
            .background(AppTheme.surface)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.border, lineWidth: 0.5)
            )
        }
    }
    
    private func subscriptionRow(name: String, amount: String, status: String, isDraining: Bool) -> some View {
        HStack(spacing: 16) {
            Circle()
                .fill(isDraining ? AppTheme.brightRed.opacity(0.15) : AppTheme.surfaceElevated)
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: isDraining ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .foregroundColor(isDraining ? AppTheme.brightRed : AppTheme.textSecondary)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text(status)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isDraining ? AppTheme.orangeYellow : AppTheme.textTertiary)
            }
            
            Spacer()
            
            Text(amount)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    // MARK: - Recovery Strategy
    private var recoveryStrategySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("OPTIMAL RECOVERY STRATEGY")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(AppTheme.textSecondary)
                Spacer()
                Text("AI Powered")
                    .font(.system(size: 10, weight: .black))
                    .tracking(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.deepViolet.opacity(0.3))
                    .foregroundColor(AppTheme.deepViolet)
                    .cornerRadius(8)
            }
            
            HStack(spacing: 12) {
                strategyCard(
                    title: "Avalanche",
                    time: "48 mos",
                    interest: "$12K Int.",
                    isSelected: false
                )
                
                strategyCard(
                    title: "AI Optimal",
                    time: "32 mos",
                    interest: "$8.2K Int.",
                    isSelected: true
                )
            }
            
            Text("AI Strategy re-allocates unused subscriptions to high-interest principal, saving you $3,800 and 16 months compared to the Avalanche method.")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.textTertiary)
                .lineSpacing(4)
        }
    }
    
    private func strategyCard(title: String, time: String, interest: String, isSelected: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isSelected ? AppTheme.textPrimary : AppTheme.textSecondary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.orangeYellow)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(time)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(isSelected ? AppTheme.textPrimary : AppTheme.textSecondary)
                
                Text(interest)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? AppTheme.brightRed : AppTheme.textTertiary)
            }
        }
        .padding(16)
        .background(isSelected ? AppTheme.surfaceElevated : AppTheme.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? AppTheme.orangeYellow : AppTheme.border, lineWidth: isSelected ? 1.5 : 0.5)
        )
    }
}

struct DebtLiquidationFlowView_Previews: PreviewProvider {
    static var previews: some View {
        DebtLiquidationFlowView()
    }
}
