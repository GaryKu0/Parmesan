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
