import SwiftUI
import CoreHaptics

#Preview {
    DragDemo()
}

struct DragDemo: View {
    
    @State var isLocked: Bool = true
    @State var isLoading: Bool = false
    
    let main = Color.orange
    let layer2 = Color.gray
    let mainLabel = Color.green
    let secondaryLabel = Color.secondary
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                BackgroundComponent(color: layer2, secondaryLabel: secondaryLabel)
                DraggingComponent(
                    isLocked: $isLocked, isLoading: isLoading,
                    maxWidth: geometry.size.width,
                    main: Color.orange, 
                    layer2: Color.red,
                    mainLabel: Color.green, 
                    secondaryLabel: Color.secondary
                )
            }
        }
        .frame(height: 56)
        .padding()
        .padding(.bottom, 20)
        .onChange(of: isLocked) { isLocked in
            guard !isLocked else { return }
            simulateRequest()
        }
    }
    
    private func simulateRequest() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
        }
    }
}

public struct DraggingComponent: View {

    @Binding var isLocked: Bool
    let isLoading: Bool
    let maxWidth: CGFloat
    
    let main: Color
    let layer2: Color
    let mainLabel: Color
    let secondaryLabel: Color

    @State private var width = CGFloat(98)
    private  let minWidth = CGFloat(98)

    init(isLocked: Binding<Bool>, isLoading: Bool, maxWidth: CGFloat,
         main: Color, layer2: Color, mainLabel: Color, secondaryLabel: Color) {
        _isLocked = isLocked
        self.isLoading = isLoading
        self.maxWidth = maxWidth
        
        self.main = main
        self.layer2 = layer2
        self.mainLabel = mainLabel
        self.secondaryLabel = secondaryLabel
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(main)
            .frame(width: width)
            .overlay(
                Button(action: { }) {
                    ZStack {
                        image(name: "arrow.right", isShown: isLocked)
                        progressView(isShown: isLoading)
                        image(name: "checkmark", isShown: !isLocked && !isLoading)
                    }
                    .animation(.easeIn(duration: 0.35).delay(0.55), value: !isLocked && !isLoading)
                }
                .buttonStyle(BaseButtonStyle())
                .disabled(!isLocked || isLoading),
                alignment: .trailing
            )
        
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        guard isLocked else { return }
                        if value.translation.width > 0 {
                            width = min(max(value.translation.width + minWidth, minWidth), maxWidth)
                        }
                    }
                    .onEnded { value in
                        guard isLocked else { return }
                        if width < maxWidth {
                            width = minWidth
                            UINotificationFeedbackGenerator().notificationOccurred(.warning)
                        } else {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            withAnimation(.spring().delay(0.5)) {
                                isLocked = false
                            }
                        }
                    }
            )
            .animation(.spring(response: 0.5, dampingFraction: 1, blendDuration: 0), value: width)

    }

    private func image(name: String, isShown: Bool) -> some View {
        Image(systemName: name)
            .font(.system(size: 20, weight: .regular, design: .rounded))
            .foregroundColor(Color.white)
            .frame(width: 90, height: 56)
            .padding(4)
            .opacity(isShown ? 1 : 0)
            .scaleEffect(isShown ? 1 : 0.01)
    }

    private func progressView(isShown: Bool) -> some View {
        ProgressView()
            .progressViewStyle(.circular)
            .foregroundColor(.white)
            .opacity(isShown ? 1 : 0)
            .scaleEffect(isShown ? 1 : 0.01)
    }
}

public struct BackgroundComponent: View {
    let color: Color
    let secondaryLabel: Color
    init(color: Color, secondaryLabel: Color) {
        self.color = color
        self.secondaryLabel = secondaryLabel
    }

    public var body: some View {
        ZStack(alignment: .leading)  {
            RoundedRectangle(cornerRadius: 16)
                .fill(color)

            Text("Slide to confirm")
                .font(.callout.weight(.regular))
                .bold()
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
        }
    }

}

public struct BaseButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.default, value: configuration.isPressed)
    }

}
