//
//  ChatListView.swift
//  Parmesan
//
//  Created by 郭粟閣 on 2024/6/13.
//

import SwiftUI

struct ChatListView: View {
    @State private var chatRooms: [ChatRoom] = []
    @State private var isLoading = true
    @State private var fetchError: Error?

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else if let fetchError = fetchError {
                    Text("Error loading chats: \(fetchError.localizedDescription)")
                } else {
                    List(chatRooms) { chatRoom in
                        NavigationLink(destination: ChatDetailView(chatRoom: chatRoom)) {
                            Text(chatRoom.roomName)
                        }
                    }
                }
            }
            .navigationTitle("Chats")
            .onAppear {
                fetchChatRooms()
            }
        }
    }

    func fetchChatRooms() {
        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
            isLoading = false
            fetchError = NSError(domain: "No token found", code: -1, userInfo: nil)
            return
        }

        APIService.shared.fetchChats(token: token) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let chatRooms):
                    self.chatRooms = chatRooms
                case .failure(let error):
                    self.fetchError = error
                }
                self.isLoading = false
            }
        }
    }
}
