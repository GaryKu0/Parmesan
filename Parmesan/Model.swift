//
//  Model.swift
//  Parmesan
//
//  Created by 郭粟閣 on 2024/5/26.
//

import Foundation

struct User: Codable {
    let id: Int
    let name: String
    let email: String
    let updated_at: String
    let created_at: String
    let user_detail: [UserDetail]?
}

struct UserDetail: Codable {
    let id: Int
    let user_id: String
    let type: String
    let content: String
    let created_at: String
    let updated_at: String
}

struct IPLocationData: Decodable {
    let lat: Double
    let lon: Double
    let country: String
    let regionName: String
}

// for chat
struct ChatRoom: Codable, Identifiable {
    let id: Int
    let roomName: String
    let createdAt: String
    let updatedAt: String
    let chatMember: [ChatMember]

    enum CodingKeys: String, CodingKey {
        case id
        case roomName = "room_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case chatMember = "chat_member"
    }
}

struct ChatMember: Codable, Identifiable {
    let id: Int
    let chatroomId: Int
    let userId: Int
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case chatroomId = "chatroom_id"
        case userId = "user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct ChatMessage: Codable, Identifiable {
    let id: Int
    let senderId: Int
    let chatroomId: String
    let content: String
    let type: String
    let recall: String?
    let replyMessageId: Int?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case senderId = "sender_id"
        case chatroomId = "chatroom_id"
        case content
        case type
        case recall
        case replyMessageId = "reply_message_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        senderId = try container.decode(Int.self, forKey: .senderId)
        let chatroomIdInt = try? container.decode(Int.self, forKey: .chatroomId)
        let chatroomIdString = try? container.decode(String.self, forKey: .chatroomId)
        chatroomId = chatroomIdString ?? String(chatroomIdInt ?? 0)
        content = try container.decode(String.self, forKey: .content)
        type = try container.decode(String.self, forKey: .type)
        recall = try? container.decode(String.self, forKey: .recall)
        replyMessageId = try? container.decode(Int.self, forKey: .replyMessageId)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
    }
}



