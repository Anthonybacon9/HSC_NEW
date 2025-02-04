import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var loadingText = "Loading..."
    
    var body: some View {
        if isActive {
            // Navigate to the main content after the splash
            ContentView()
        } else {
            VStack {
                // Your splash screen logo or animation
                Image("NEPng")
                    .resizable()
                    .frame(width: 150, height: 150)
                    .foregroundColor(.green) // Match your app's theme
                    .padding()
                
                // Loading text or animation
                //                Text(loadingText)
                //                    .font(.headline)
                //                    .padding(.top, 10)
            }
            .onAppear {
                performStartupTasks()
            }
        }
    }
    
    // Simulates a network/database request or initialization
    func performStartupTasks() {
        // Simulate fetching data
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            // Switch to the main view after tasks complete
            withAnimation(.easeOut(duration: 1)) {
                isActive = true
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
