import Foundation
import SwiftUI

struct HeaderView<Content: View, Left: View, Right: View>: View {
    private var content: () -> Content
    private var left: (()->Left)?
    private var right: (()->Right)?
    
    private init(
        @ViewBuilder content: @escaping () -> Content,
        left: (() -> Left)?,
        right: (() -> Right)?
    ){
        self.content = content
        self.left = left
        self.right = right
    }
    
    var body: some View {
        // simplified body
        HStack{
            if let left {
                left()
                Spacer()
            }
            content()
            if let right {
                Spacer()
                right()
            }
        }
    }
}

extension HeaderView {
    init(@ViewBuilder content: @escaping () -> Content, @ViewBuilder left: @escaping () -> Left, @ViewBuilder right: @escaping () -> Right){
        self.content = content
        self.left = left
        self.right = right
    }
    
    init(@ViewBuilder content: @escaping () -> Content, @ViewBuilder left: @escaping () -> Left) where Right == EmptyView{
        self.init(content: content, left: left, right: nil)
    }
    
    init(@ViewBuilder content: @escaping () -> Content, @ViewBuilder right: @escaping () -> Right) where Left == EmptyView{
        self.init(content: content, left: nil, right: right)
    }
}

struct BigButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    var backgroundColor: Color = .blue
    var textColor: Color = .white
    var cornerRadius: CGFloat = 10
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.bold())
            .frame(maxWidth: .infinity)
            .padding()
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(cornerRadius)
            .saturation(isEnabled ? 1 : 0)
    }
}
