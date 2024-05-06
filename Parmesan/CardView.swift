import SwiftUI

struct CardView: View {
    var person: Person // 修改類型為 Person
    var onRemove: () -> Void // 添加这个闭包属性
    @State private var offset = CGSize.zero
    @State private var color: Color = .black
    @State private var opacity: Double = 0
    var panelManager: PanelManager
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.purple, .pink]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .frame(width: 320, height: 420)
                .cornerRadius(32)
                .shadow(radius: 10)

            Rectangle()
                .frame(width: 320, height: 420)
                .border(.gray, width: 1.0)
                .cornerRadius(32)
                .foregroundColor(color.opacity(opacity))
                .shadow(radius: 10)

            HStack {
                Text(person.name) // 使用 Person 結構的 name 屬性
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .bold()
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
            }
        }
        .offset(x: offset.width, y: offset.height * 0.4)
        .rotationEffect(.degrees(Double(offset.width / 40)))
        .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            offset = gesture.translation
                            withAnimation {
                                ChangeColor(width: offset.width)
                            }
                        }
                        .onEnded { _ in
                                if offset.width < -150 {
                                        offset = CGSize(width: -500, height: 0)
                                    SwipeCard(width:offset.width)
                                } else if offset.width > 150 {
                                    
                                    offset = CGSize(width: 500, height: 0)
                                    SwipeCard(width:offset.width)
                                } else {
                                    offset = .zero
                            
                            }
                        }
                )
    }
    
    
    func SwipeCard(width: CGFloat) {
        if width < -150 {
            DispatchQueue.main.asyncAfter(deadline: .now()+0.2){
                onRemove()
                offset = .zero
                color = .black
                opacity = .zero
            }
                                          
            
        } else if width > 150 {
            // 向右滑动足够远，准备移除卡片并显示panel
            withAnimation {
                offset = CGSize(width: 500, height: 0)
            }
            panelManager.showMatchedPanel(for: person.name) // 使用 name 属性调用
            panelManager.isPanelPresented = true
            // 延迟执行以确保动画有足够的时间完成
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                // 调用闭包通知移除
                onRemove()
                    offset = .zero
                    color = .black
                    opacity = .zero
            }
        } else {
            // 如果滑动距离不够远，直接归位
            withAnimation {
                offset = .zero
            }
        }
    }

    func ChangeColor(width: CGFloat) {
        if width < -130 {
            color = .red
            opacity = 0.6
        } else if width > 130 {
            color = .green
            opacity = 0.6
        } else {
            opacity = 0
            color = .black
        }
    }
}

//
//struct MatchedView: View {
//    let person: String
//    @Binding var item: PanelItem?
//    var body: some View {
//        VStack(spacing: 24) {
//            Text("Matched with \(person)!")
//                .font(.title)
//                .foregroundColor(.black)
//                .bold()
//
//            Image(systemName: "heart.fill")
//                .font(.system(size: 100))
//                .foregroundColor(.red)
//
//            Text("You and \(person) have liked each other.")
//                .multilineTextAlignment(.center)
//
//            Button(action: {
//                self.item = nil
//            }, label: {
//                Text("Close")
//                    .frame(maxWidth: .infinity)
//            })
//            .buttonStyle(.borderedProminent)
//            .controlSize(.large)
//        }
//        .padding()
//    }
//}

