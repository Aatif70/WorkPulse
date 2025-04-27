import SwiftUI

struct ToastView: View {
    let message: String
    let isSuccess: Bool
    @Binding var isShowing: Bool
    
    @State private var offset: CGFloat = 100
    @State private var opacity: Double = 0
    
    var body: some View {
        VStack {
            HStack(spacing: 12) {
                Image(systemName: isSuccess ? "checkmark.circle.fill" : "play.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        isShowing = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                isSuccess ? Color.appSuccess : Color.appAccent
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 16)
        }
        .offset(y: offset)
        .opacity(opacity)
        .onChange(of: isShowing) { oldValue, newValue in
            if newValue {
                showToast()
            }
        }
    }
    
    private func showToast() {
        // Automatically dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.spring(response: 0.3)) {
                isShowing = false
            }
        }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            offset = 0
            opacity = 1
        }
    }
}

struct ToastModifier: ViewModifier {
    @Binding var isShowing: Bool
    let message: String
    let isSuccess: Bool
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            VStack {
                Spacer()
                
                if isShowing {
                    ToastView(message: message, isSuccess: isSuccess, isShowing: $isShowing)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(100)
                        .padding(.bottom, 90) // Position above the timer button
                }
            }
            .animation(.spring(response: 0.5), value: isShowing)
        }
    }
}

extension View {
    func toast(isShowing: Binding<Bool>, message: String, isSuccess: Bool = true) -> some View {
        self.modifier(ToastModifier(isShowing: isShowing, message: message, isSuccess: isSuccess))
    }
} 