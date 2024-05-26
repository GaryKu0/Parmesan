//
//  APIService.swift
//  Parmesan
//
//  Created by 郭粟閣 on 2024/5/26.
//

import Foundation

class APIService {
    static let shared = APIService()
    private init() {}

    func register(name: String, email: String, password: String) async throws -> RegisterResponse {
        guard let url = URL(string: APIConfig.baseURL + APIConfig.registerEndpoint) else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = ""
        body += "--\(boundary)\r\n"
        body += "Content-Disposition: form-data; name=\"name\"\r\n\r\n"
        body += "\(name)\r\n"
        body += "--\(boundary)\r\n"
        body += "Content-Disposition: form-data; name=\"password\"\r\n\r\n"
        body += "\(password)\r\n"
        body += "--\(boundary)\r\n"
        body += "Content-Disposition: form-data; name=\"email\"\r\n\r\n"
        body += "\(email)\r\n"
        body += "--\(boundary)--\r\n"

        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw NSError(domain: "API Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "API request failed"])
        }
        return try JSONDecoder().decode(RegisterResponse.self, from: data)
    }

    func login(email: String, password: String) async throws -> LoginResponse {
        guard let url = URL(string: APIConfig.baseURL + APIConfig.loginEndpoint) else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let params = "email=\(email)&password=\(password)"
        request.httpBody = params.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw NSError(domain: "API Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "API request failed"])
        }
        return try JSONDecoder().decode(LoginResponse.self, from: data)
    }

    func fetchUserInfo(token: String) async throws -> User {
        guard let url = URL(string: APIConfig.baseURL + APIConfig.userInfoEndpoint) else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw NSError(domain: "API Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "API request failed"])
        }
        return try JSONDecoder().decode(User.self, from: data)
    }
}
