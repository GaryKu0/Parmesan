import SwiftUI

struct ChatDetailView: View {
    let chatRoom: ChatRoom
    @State private var messages: [ChatMessage] = []
    @State private var newMessage = ""
    @State private var isLoading = true
    @State private var fetchError: Error?
    @State private var errorMessage: String?
    @State private var timer: Timer?

    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else if let fetchError = fetchError {
                Text("Error loading messages: \(fetchError.localizedDescription)")
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(messages) { message in
                                MessageView(message: message)
                            }
                        }
                        .padding()
                        .onChange(of: messages.count) { _ in
                            proxy.scrollTo(messages.last?.id, anchor: .bottom)
                        }
                    }
                }
            }

            if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
            }

            HStack {
                TextField("Enter message", text: $newMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .padding()
                        .foregroundColor(.blue)
                }
            }
            .edgesIgnoringSafeArea(.bottom)
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(16)
        }
        .navigationTitle(chatRoom.roomName)
        .onAppear {
            checkUserIdAndFetchMessages()
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }

    func checkUserIdAndFetchMessages() {
        if UserDefaults.standard.integer(forKey: "userId") == 0 {
            guard let token = UserDefaults.standard.string(forKey: "userToken") else {
                isLoading = false
                fetchError = NSError(domain: "No token found", code: -1, userInfo: nil)
                return
            }

            Task {
                do {
                    let user = try await APIService.shared.fetchUserInfo(token: token)
                    UserDefaults.standard.set(user.id, forKey: "userId")
                    fetchMessages()
                } catch {
                    fetchError = error
                    isLoading = false
                }
            }
        } else {
            fetchMessages()
        }
    }

    func fetchMessages() {
        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
            isLoading = false
            fetchError = NSError(domain: "No token found", code: -1, userInfo: nil)
            return
        }

        APIService.shared.fetchChatMessages(token: token, roomId: chatRoom.id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let messages):
                    self.messages = messages
                case .failure(let error):
                    self.fetchError = error
                    self.errorMessage = error.localizedDescription
                }
                self.isLoading = false
            }
        }
    }

    func sendMessage() {
        guard !newMessage.isEmpty, let token = UserDefaults.standard.string(forKey: "userToken") else {
            return
        }

        APIService.shared.sendMessage(token: token, roomId: chatRoom.id, content: newMessage) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let message):
                    self.messages.append(message)
                    self.newMessage = ""
                case .failure(let error):
                    self.fetchError = error
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            fetchMessages()
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

struct MessageView: View {
    let message: ChatMessage

    var body: some View {
        let currentUserId = UserDefaults.standard.integer(forKey: "userId")
        
        HStack {
            if message.senderId == currentUserId {
                Spacer()
                Text(message.content)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .frame(maxWidth: 250, alignment: .trailing)
                    .id(message.id)
            } else {
                Text(message.content)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.black)
                    .cornerRadius(10)
                    .frame(maxWidth: 250, alignment: .leading)
                    .id(message.id)
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}
