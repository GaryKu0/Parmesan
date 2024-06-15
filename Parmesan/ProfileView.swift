import SwiftUI
import PhotosUI
import SDWebImageSwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss // 用于关闭 ProfileView
    @Binding var isLoggedIn: Bool // 綁定 isLoggedIn 狀態
    @Binding var showingAuth: Bool // 綁定 showingAuth 狀態
    @State private var isEditing = false // 是否处于编辑状态
    @State private var user: User? // 用户信息
    @State private var isLoading = true // 是否正在加载数据
    @State private var showingImagePicker = false // 显示图片选择器
    @State private var selectedImageData: Data? // 选中的图片数据
    @State private var imageTypeToUpload: String? // 要上传的图片类型
    @State private var showingImageGrid = false // 是否显示图片网格
    @State private var matchRadius: Double = UserDefaults.standard.double(forKey: "matchRadius") == 0 ? 100 : UserDefaults.standard.double(forKey: "matchRadius") // 默認匹配半徑

    var refreshPeople: (Double) -> Void // 傳遞的函數，用來重新請求卡片

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView() // 显示加载指示器
                        .progressViewStyle(CircularProgressViewStyle())
                } else if let user = user {
                    // 顯示大頭貼
                    if let userProfilePhoto = user.user_detail?.first(where: { $0.type == "img1" })?.content,
                       let url = URL(string: userProfilePhoto) {
                        WebImage(url: url)
                            .onSuccess { image, data, cacheType in
                                // 图片加载成功后的处理
                                print("Loaded image from URL: \(userProfilePhoto)")
                            }
                            .resizable()
                            .scaledToFill()
                            .frame(width: 200, height: 200)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 4))
                            .shadow(radius: 7)
                            .onTapGesture {
                                showingImagePicker = true
                                imageTypeToUpload = "img1"
                            }
                    } else {
                        Image("capybara") // 默认头像
                            .resizable()
                            .scaledToFill()
                            .frame(width: 200, height: 200)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 4))
                            .shadow(radius: 7)
                            .onTapGesture {
                                showingImagePicker = true
                                imageTypeToUpload = "img1"
                            }
                    }
                    Spacer()
                    // 显示用户信息
                    Text(user.name)
                        .font(.largeTitle)
                    Text(user.email)
                        .font(.title)
                    
                    // 添加滑桿來調整匹配半徑
                    VStack {
                        Text("Match Radius: \(Int(matchRadius)) km")
                        Slider(value: $matchRadius, in: 1...200, step: 1)
                            .padding()
                            .onChange(of: matchRadius) { newValue in
                                UserDefaults.standard.set(newValue, forKey: "matchRadius")
                                refreshPeople(newValue)
                            }
                    }
                    
                    Spacer()
                    // 添加登出按钮
                    Button(action: {
                        UserDefaults.standard.removeObject(forKey: "userToken")
                        UserDefaults.standard.removeObject(forKey: "userId")
                        isLoggedIn = false // 更新 isLoggedIn 狀態
                        showingAuth = true // 顯示登入視圖
                        dismiss()
                    }) {
                        Text("Logout")
                            .foregroundColor(.red)
                            .font(.headline)
                    }
                } else {
                    Text("Failed to load user info.") // 加载用户信息失败时的提示
                }
            }
            .padding()
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingImageGrid = true
                    }) {
                        Text("Add")
                    }
                }
            }
            .onAppear {
                fetchUserInfo() // 在视图出现时获取用户信息
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(imageData: $selectedImageData, onImagePicked: { data in
                    if let data = data, let imageType = imageTypeToUpload {
                        uploadProfileImage(imageData: data, imageType: imageType)
                    }
                    showingImagePicker = false // 关闭图片选择器
                })
            }
            .sheet(isPresented: $showingImageGrid) {
                ImageGrid(user: $user, showingImagePicker: $showingImagePicker, imageTypeToUpload: $imageTypeToUpload, showingImageGrid: $showingImageGrid)
            }
        }
    }

    func fetchUserInfo() {
        isLoading = true
        Task {
            do {
                guard let token = UserDefaults.standard.string(forKey: "userToken") else {
                    print("Token not found.")
                    isLoading = false
                    return
                }
                let fetchedUser = try await APIService.shared.fetchUserInfo(token: token)
                DispatchQueue.main.async {
                    self.user = fetchedUser
                    self.isLoading = false
                }
            } catch {
                print("Error fetching user info: \(error.localizedDescription)")
                self.isLoading = false
            }
        }
    }

    func uploadProfileImage(imageData: Data, imageType: String) {
        isLoading = true
        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
            print("Token not found.")
            isLoading = false
            return
        }
        APIService.shared.uploadImage(token: token, imageData: imageData, imageType: imageType) { success, error in
            DispatchQueue.main.async {
                if success {
                    print("Image uploaded successfully")
                    self.fetchUserInfo() // 重新获取用户信息以更新头像
                } else {
                    print("Failed to upload image: \(error?.localizedDescription ?? "Unknown error")")
                }
                self.isLoading = false
            }
        }
    }
}

struct ImageGrid: View {
    @Binding var user: User?
    @Binding var showingImagePicker: Bool
    @Binding var imageTypeToUpload: String?
    @Binding var showingImageGrid: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 20) {
                        ForEach(0..<3, id: \.self) { col in
                            let index = row * 3 + col + 1
                            if let imageURL = user?.user_detail?.first(where: { $0.type == "img\(index)" })?.content, let url = URL(string: imageURL) {
                                WebImage(url: url)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Rectangle())
                                    .overlay(Rectangle().stroke(Color.white, lineWidth: 2))
                                    .shadow(radius: 5)
                                    .onTapGesture {
                                        imageTypeToUpload = "img\(index)"
                                        showingImagePicker = true
                                    }
                            } else {
                                Image(systemName: "plus")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40) // 調整 "+ "號的大小
                                    .padding(30) // 增加內縮，使其在 100x100 的框內顯得較小
                                    .background(Color.gray.opacity(0.2)) // 添加背景以使其更加明顯
                                    .clipShape(Rectangle())
                                    .foregroundColor(.gray)
                                    .onTapGesture {
                                        imageTypeToUpload = "img\(index)"
                                        showingImagePicker = true
                                    }
                            }
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("Add Photos")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingImageGrid = false // 關閉 sheet
                    }) {
                        Text("Done")
                    }
                }
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    var onImagePicked: (Data?) -> Void

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.imageData = nil
            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
                parent.onImagePicked(nil)
                picker.dismiss(animated: true, completion: nil)
                return
            }

            provider.loadObject(ofClass: UIImage.self) { image, error in
                if let image = image as? UIImage, let data = image.jpegData(compressionQuality: 0.8) {
                    DispatchQueue.main.async {
                        self.parent.imageData = data
                        self.parent.onImagePicked(data)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.parent.onImagePicked(nil)
                    }
                }
            }
            picker.dismiss(animated: true, completion: nil)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
}
