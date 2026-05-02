import SwiftUI
import LocalAuthentication

struct MainFlowView: View {
    @State private var viewModel = DebtFlowViewModel()
    @State private var path = NavigationPath()
    
    // Security States
    @Environment(\.scenePhase) var scenePhase
    @State private var isUnlocked = false
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                AntigravityTheme.backgroundGradient
                
                InputScreen(viewModel: viewModel, onCalculate: {
                    viewModel.calculateReality()
                    path.append("result")
                })
            }
            .navigationDestination(for: String.self) { destination in
                if destination == "result" {
                    ResultScreen(viewModel: viewModel)
                }
            }
        }
        // Privacy Blur
        .blur(radius: scenePhase == .active ? 0 : 20)
        // Biometric Lock Overlay
        .overlay {
            if !isUnlocked {
                ZStack {
                    AntigravityTheme.backgroundGradient.ignoresSafeArea()
                    VStack(spacing: 20) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.white)
                        Text("DebtFlow is Locked")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Button("Unlock with FaceID") {
                            authenticate()
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .foregroundStyle(.white)
                    }
                }
            }
        }
        .onAppear(perform: authenticate)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                // Wipe state if incognito
                if viewModel.isIncognitoMode {
                    viewModel.resetSession()
                }
                // Lock app when sent to background
                isUnlocked = false
            } else if newPhase == .active && !isUnlocked {
                authenticate()
            }
        }
    }
    
    private func authenticate() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock your financial overview") { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        withAnimation { self.isUnlocked = true }
                    }
                }
            }
        } else {
            // Fallback for devices without biometrics or simulator
            DispatchQueue.main.async {
                withAnimation { self.isUnlocked = true }
            }
        }
    }
}

struct MainFlowView_Previews: PreviewProvider {
    static var previews: some View {
        MainFlowView()
    }
}
