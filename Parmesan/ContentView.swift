import SwiftUI
import Panel
import CoreLocation

enum PanelItem: String, Identifiable {
    case matched
    var id: String { self.rawValue }
}

struct ContentView: View {
    @StateObject private var panelManager = PanelManager()
    @State private var selectedItem: PanelItem? = nil
    @State private var showingAuth = false
    @State private var isLoggedIn = false
    @State private var user: User? // 存储用户信息
    @State private var showingChatList = false // 顯示聊天列表

    @State private var people: [Person] = []
    @State private var isLoadingPeople = false
    @State private var fetchError: Error? // 存储获取数据错误
    @State private var showingProfile = false
    @State private var matchRadius: Double = UserDefaults.standard.double(forKey: "matchRadius") == 0 ? 100 : UserDefaults.standard.double(forKey: "matchRadius") // 默認匹配半徑
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Text("Welcome!")
                        .font(.largeTitle)
                        .bold()
                    Spacer()
                    Button(action: {
                        if isLoggedIn {
                            // 用户已登录，跳转到用户信息页面
                            print("跳转到用户信息页面")
                            showingProfile = true
                        } else {
                            // 用户未登录，显示登录/注册页面
                            showingAuth = true
                        }
                    }) {
                        Image("capybara")
                            .resizable()
                            .frame(maxWidth: 50, maxHeight: 50)
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(50)
                    }
                }
                .padding(.horizontal)
                .frame(maxHeight: 100)

                Spacer()

                if isLoadingPeople {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else if let error = fetchError {
                    Text("Error loading data: \(error.localizedDescription)")
                } else if people.isEmpty {
                    Text("No people found nearby.")
                } else {
                    ZStack {
                        Text("You reached the daily limit!")
                            .font(.headline)
                            .bold()

                        ForEach(Array(people.prefix(5).indices.reversed()), id: \.self) { index in
                            CardView(person: people[index], onRemove: {
                                withAnimation {
                                    if !people.isEmpty {
                                        people.remove(at: index)
                                    }
                                }
                            }, panelManager: panelManager)
                            .offset(x: 0, y: CGFloat(index * -10))
                        }
                    }
                }

                HStack {
                    Button(action: {
                        dislikeTopCard()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.red)
                    }

                    Button(action: {
                        likeTopCard()
                    }) {
                        Image(systemName: "heart.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.green)
                    }
                }
                .padding(.top, 36)

                Spacer()
            }
            .padding()
            .panel(item: $panelManager.selectedItem,
                   onCancel: { print("cancelled") },
                   content: { item in
                       if let currentPerson = panelManager.currentPerson {
                           MatchedView(person: currentPerson, item: self.$panelManager.selectedItem)
                       }
                   })
            .environmentObject(panelManager)
            .sheet(isPresented: $showingAuth) {
                AuthView(showingAuth: $showingAuth, isLoggedIn: $isLoggedIn, user: $user, refreshPeople: refreshPeople) // 传递 refreshPeople 函数
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView(isLoggedIn: $isLoggedIn, showingAuth: $showingAuth, refreshPeople: { radius in
                    matchRadius = radius
                    fetchPeople()
                }) // 傳遞 isLoggedIn 和 showingAuth 綁定以及 refreshPeople 函數
            }
            .sheet(isPresented: $showingChatList) {
                ChatListView()
            }

            // 浮動的聊天按鈕
            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        showingChatList = true
                    }) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.blue)
                            .padding(10) // 調整 padding 以更貼近底部
                            .background(Color.white)
                            .clipShape(Circle())
                            .padding(.bottom, 24) // 調整 padding 以更貼近底部
                            .padding(.leading, 24)
                    }
                    Spacer()
                }
            }
            .edgesIgnoringSafeArea(.bottom) // 使按鈕更貼近屏幕底部
        }
        .onAppear {
            fetchPeople()
        }
    }

    func likeTopCard() {
        guard !people.isEmpty else { return }
        let person = people.removeFirst()
        Task {
            do {
                let message = try await APIService.shared.likeUser(userID:person.id)
                let PrintOutMessage = message + " " + person.name
                print(PrintOutMessage) // 输出 "Liked"
                if message == "Matched" {
                    print("Showing Matched with \(person.name)")
                    panelManager.showMatchedPanel(for: person.name) // Trigger popup
                }
            } catch {
                print("Error liking user:", error)
            }
        }
    }

    func dislikeTopCard() {
        guard !people.isEmpty else { return }
        let person = people.removeFirst()
        print("(Clicked) Disliked \(person.name)")
    }

    func refreshPeople() {
        fetchPeople()
    }
    
    func fetchPeople() {
        isLoadingPeople = true
        fetchError = nil // 重置错误状态

        // 使用 IP 获取位置
        APIService.shared.fetchLocationFromIP { location, error in
            guard let location = location else {
                DispatchQueue.main.async {
                    self.isLoggedIn = false
                    self.showingAuth = true // 顯示登錄頁面
                    self.isLoadingPeople = false
                    self.fetchError = error
                }
                return
            }

            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude

            APIService.shared.fetchPeople(latitude: latitude, longitude: longitude, radius: matchRadius) { fetchedPeople, error in
                DispatchQueue.main.async {
                    self.isLoadingPeople = false
                    if let error = error {
                        self.isLoggedIn = false
                        self.showingAuth = true // 顯示登錄頁面
                        self.fetchError = error
                        print("Error fetching people: \(error.localizedDescription)")
                    } else if let fetchedPeople = fetchedPeople {
                        self.isLoggedIn = true
                        self.people = fetchedPeople
                        
                    }
                }
            }
        }
    }
}

struct MatchedView: View {
    let person: String
    @Binding var item: PanelItem?

    var body: some View {
        VStack(spacing: 24) {
            Text("Matched with \(person)!")
                .font(.title)
                .foregroundColor(.black)
                .bold()

            Image(systemName: "heart.fill")
                .font(.system(size: 100))
                .foregroundColor(.red)

            Text("You and \(person) have liked each other.")
                .multilineTextAlignment(.center)

            Button(action: {
                self.item = nil
            }, label: {
                Text("Close")
                    .frame(maxWidth: .infinity)
            })
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
