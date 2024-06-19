import SwiftUI
import SDWebImageSwiftUI

struct ImageItem: Identifiable {
    var id: String { url }
    let url: String
}


struct CardView: View {
    var person: Person
    var onRemove: () -> Void
    @State private var offset = CGSize.zero
    @State private var color: Color = .black
    @State private var opacity: Double = 0
    var panelManager: PanelManager
    @State private var showUserInfo = false // 添加此狀態變量
    @State private var selectedImage: ImageItem? // 用於放大預覽的選中圖片

    // 添加預設頭像圖片
    private let defaultImage = Image(systemName: "person.circle.fill") // 或者使用你自己的圖片

    var body: some View {
        ZStack {
            // 底色
            Rectangle()
                .fill(Color.white)
                .frame(width: 320, height: 420)
                .border(Color.gray, width: 1.0)
                .cornerRadius(32)
                .shadow(radius: 10)
            
            // 使用 WebImage 加載圖片並作為背景
            if let userProfilePhoto = person.UserProfilePhoto, let url = URL(string: userProfilePhoto) {
                WebImage(url: url)
                    .onSuccess { image, data, cacheType in
                        // 圖片加載成功後的處理
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 320, height: 420)
                    .cornerRadius(32)
                    .clipped()
            } else {
                // 用戶沒有圖片時顯示預設圖片
                defaultImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
            }

            // 從下往上漸淡的白色漸層
            LinearGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.8), Color.white.opacity(0)]),
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(width: 320, height: 120)
            .cornerRadius(32)
            .offset(y: 150)

            // 內容層
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
                            // 點擊查看詳情按鈕的邏輯
                            showUserInfo = true // 打開用戶信息 Sheet
                            print("查看詳情")
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
        .sheet(isPresented: $showUserInfo) {
            UserInfoView(person: person, selectedImage: $selectedImage) // 傳遞用戶信息和選中圖片
        }
        .fullScreenCover(item: $selectedImage) { imageItem in
            WebImage(url: URL(string: imageItem.url))
                .resizable()
                .scaledToFit()
                .background(Color.black)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    selectedImage = nil
                }
        }
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

struct UserInfoView: View {
    var person: Person
    @Binding var selectedImage: ImageItem?
    
    var body: some View {
        ZStack {
            VStack {
                // 頭像
                if let userProfilePhoto = person.UserProfilePhoto, let url = URL(string: userProfilePhoto) {
                    WebImage(url: url)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                        .shadow(radius: 10)
                        .padding(.top, 50)
                        .transition(.scale)
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                        .shadow(radius: 10)
                        .padding(.top, 50)
                        .transition(.scale)
                }

                // 名字
                Text(person.name)
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.primary)
                    .padding(.top, 20)
                    .transition(.slide)
                
                // 電子郵件
                Text("Email: \(person.email)")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.top, 10)
                    .transition(.opacity)
                
                // 距離
                Text("Distance: \(person.distance) km")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.top, 5)
                    .transition(.opacity)
                
                // 圖片畫廊
                if let images = person.images, !images.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(images, id: \.self) { imageUrl in
                                if let url = URL(string: imageUrl) {
                                    WebImage(url: url)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .shadow(radius: 5)
                                        .onTapGesture {
                                            selectedImage = ImageItem(url: imageUrl)
                                        }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 20)
                }
                
                Spacer()
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.white, Color.blue.opacity(0.1)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
            )
            .cornerRadius(20)
            .shadow(radius: 20)
            .animation(.easeInOut)

            // 放大圖片預覽
            if let selectedImage = selectedImage {
                Color.black.opacity(0.8)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        self.selectedImage = nil
                    }

                WebImage(url: URL(string: selectedImage.url))
                    .resizable()
                    .scaledToFit()
                    .background(Color.black)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        self.selectedImage = nil
                    }
            }
        }
    }
}
