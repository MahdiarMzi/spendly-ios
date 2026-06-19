import SwiftUI

struct SplashView: View {
    @State private var emojiOffset: CGFloat = 300
    @State private var emojiOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 20
    @State private var nameOpacity: Double = 0
    @State private var bgScale: CGFloat = 1.0

    let name: String
    let onFinish: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()
            
            // Glow circle behind emoji
            Circle()
                .fill(Color(hex: "FFE66D").opacity(0.08))
                .frame(width: 200, height: 200)
                .scaleEffect(bgScale)

            VStack(spacing: 16) {
                Text("💸")
                    .font(.system(size: 90))
                    .offset(y: emojiOffset)
                    .opacity(emojiOpacity)

                Text("Spendly")
                    .font(.system(size: 40, weight: .black))
                    .foregroundColor(.white)
                    .offset(y: titleOffset)
                    .opacity(titleOpacity)

                if !name.isEmpty {
                    Text("Welcome back, \(name) 👋")
                        .font(.system(size: 17))
                        .foregroundColor(Color(hex: "666666"))
                        .opacity(nameOpacity)
                }
            }
        }
        .onAppear {
            // Emoji slides up with bounce
            withAnimation(.interpolatingSpring(stiffness: 120, damping: 10)) {
                emojiOffset = 0
                emojiOpacity = 1
            }
            
            // Glow pulses
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                bgScale = 1.3
            }

            // Title fades in
            withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
                titleOpacity = 1
                titleOffset = 0
            }

            // Name fades in
            withAnimation(.easeIn(duration: 0.4).delay(0.7)) {
                nameOpacity = 1
            }

            // Exit
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.4)) {
                    emojiOpacity = 0
                    titleOpacity = 0
                    nameOpacity = 0
                    bgScale = 0.1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    onFinish()
                }
            }
        }
    }
}
