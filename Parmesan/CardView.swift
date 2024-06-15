import SwiftUI
import SDWebImageSwiftUI

struct CardView: View {
    var person: Person
    var onRemove: () -> Void
    @State private var offset = CGSize.zero
    @State private var color: Color = .black
    @State private var opacity: Double = 0
    var panelManager: PanelManager

    // 添加默认头像图片
    private let defaultImage = Image(systemName: "person.circle.fill") // 或者使用你自己的图片

    var body: some View {
        ZStack {
            // 底色
            Rectangle()
                .fill(Color.white)
                .frame(width: 320, height: 420)
                .border(Color.gray, width: 1.0)
                .cornerRadius(32)
                .shadow(radius: 10)
            
            // 使用 WebImage 加载图片并作为背景
            if let userProfilePhoto = person.UserProfilePhoto, let url = URL(string: userProfilePhoto) {
                WebImage(url: url)
                    .onSuccess { image, data, cacheType in
                        // 图片加载成功后的处理
//                        print("Loaded image from URL: \(userProfilePhoto)")
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 320, height: 420)
                    .cornerRadius(32)
                    .clipped()
            } else {
                // 用户没有图片时显示默认图片
                defaultImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .cornerRadius(32)
                    .clipped()
            }

            // 从下往上渐淡的白色渐层
            LinearGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.8), Color.white.opacity(0)]),
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(width: 320, height: 120)
            .cornerRadius(32)
            .offset(y: 150)

            // 内容层
            VStack {
                Spacer()

                VStack {
                    HStack {
                        Text(person.name)
                            .font(.title2)
                            .foregroundColor(.black)
                            .bold()
                        Spacer()
                        Button(action: {
                            // 点击查看详情按钮的逻辑
                            print("查看详情")
                        }) {
                            Text("More")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.green)
                                .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .frame(width: 320, height: 420) // 確保內容在卡片內部
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
                        SwipeCard(width: offset.width)
                    } else if offset.width > 150 {
                        offset = CGSize(width: 500, height: 0)
                        SwipeCard(width: offset.width)
                    } else {
                        offset = .zero
                    }
                }
        )
    }

    func SwipeCard(width: CGFloat) {
        if width < -150 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                onRemove()
                offset = .zero
                color = .black
                opacity = .zero
            }
        } else if width > 150 {
            withAnimation {
                offset = CGSize(width: 500, height: 0)
            }
            Task {
                do {
                    let message = try await APIService.shared.likeUser(userID: person.id)
                    print(message)
                    if message == "Matched" {
                        panelManager.showMatchedPanel(for: person.name)
                        panelManager.isPanelPresented = true
                    }
                } catch {
                    print("Error liking user:", error)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onRemove()
                offset = .zero
                color = .black
                opacity = .zero
            }
        } else {
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
