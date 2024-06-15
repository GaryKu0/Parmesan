//
//  Response.swift
//  Parmesan
//
//  Created by 郭粟閣 on 2024/5/26.
//

import Foundation

struct RegisterResponse: Codable {
    let user: User
}

struct LoginResponse: Codable {
    let token: String?
}
