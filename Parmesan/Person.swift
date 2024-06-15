//
//  Person.swift
//  Parmesan
//
//  Created by 郭粟閣 on 2024/5/6.
//

import Foundation

//struct Person {
//    let name: String
//    let age: Int
//    let city: String
//}

struct Person: Decodable, Identifiable {
    let id: Int
    let name: String
    let email: String
    let lat: String
    let lng: String
    let distance: Double
    var UserProfilePhoto: String?
}

