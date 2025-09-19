import SwiftUI

// This is a helper file to generate app icons programmatically
// You can use this to create a simple icon for testing

struct AppIconGenerator: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue, Color.purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Main icon content
            VStack(spacing: 8) {
                // Dumbbell icon
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.white)
                
                // App name
                Text("StrongMe")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 1024, height: 1024)
    }
}

#Preview {
    AppIconGenerator()
}
