//
//  APIService.swift
//  Parmesan
//
//  Created by 郭粟閣 on 2024/5/26.
//

import Foundation
import CoreLocation

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
        let loginResponse = try await login(email: email, password: password)
                
        // 将登录响应的 token 存储到 UserDefaults 中
        UserDefaults.standard.set(loginResponse.token, forKey: "userToken")
        UserDefaults.standard.synchronize()
        // grab token from user defaults
        print(UserDefaults.standard.string(forKey: "userToken")!)
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
        
        let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
        
        UserDefaults.standard.set(loginResponse.token, forKey: "userToken")
        UserDefaults.standard.synchronize()
        
        return loginResponse
    }
    //以下是取得個人的, 和取得他人的使用同一個api端點 但稍微有些不同
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
    func fetchOtherUserInfo(userId: Int) async throws -> User {
        let endpoint = APIConfig.baseURL + APIConfig.otherUserInfoEndpoint + "\(userId)"
        guard let url = URL(string: endpoint) else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw NSError(domain: "API Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "API request failed"])
        }
        return try JSONDecoder().decode(User.self, from: data)
    }
//    func fetchPeople(latitude: Double, longitude: Double, radius: Double, completion: @escaping ([Person]?, Error?) -> Void) {
//        // 使用 APIConfig.waterfallEndpoint 构建 URL
//        let endpoint = "\(APIConfig.waterfallEndpoint)?lat=\(latitude)&lng=\(longitude)&farFromme=\(radius)"
//        guard let url = URL(string: APIConfig.baseURL + endpoint) else {
//            completion(nil, NSError(domain: "Invalid URL", code: -1, userInfo: nil))
//            return
//        }
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET" // 设置请求方法为 GET
//        
//        // 从 UserDefaults 中读取 token
//        if let token = UserDefaults.standard.string(forKey: "userToken") {
//            // 添加 Authorization 头部
//            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
//        } else {
//            // 处理 token 不存在的情况，例如：
//            print("Token not found. Request might fail.")
//            // 或者 completion(nil, NSError(domain: "Missing Token", code: -3, userInfo: nil))
//        }
//        
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                completion(nil, error)
//                return
//            }
//            
//            guard let data = data else {
//                completion(nil, NSError(domain: "No data received", code: -2, userInfo: nil))
//                return
//            }
//            
//            do {
//                let decoder = JSONDecoder()
//                // 解码为 [String: Person] 字典
//                let peopleDict = try decoder.decode([String: Person].self, from: data)
//                // 将字典转换为 [Person] 数组
//                let people = Array(peopleDict.values)
//                completion(people, nil)
//            } catch {
//                print("Decoding error:", error)
//                print(String(data: data, encoding: .utf8)!)
//                completion(nil, error)
//            }
//        }.resume()
//    }
    func likeUser(userID: Int) async throws -> String {
        guard let url = URL(string: APIConfig.baseURL + APIConfig.likeUser) else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // 从 UserDefaults 中读取 token
        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
            throw NSError(domain: "Missing Token", code: -3, userInfo: nil)
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // 设置请求体
        let body = "like_user_id=\(userID)"
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw NSError(domain: "API Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "API request failed"])
        }
        
        // 解析响应数据
        let responseJSON = try JSONDecoder().decode([String: String].self, from: data)
        guard let message = responseJSON["message"] else {
            throw NSError(domain: "Invalid Response", code: -4, userInfo: nil)
        }
        return message
    }
    func fetchPeople(latitude: Double, longitude: Double, radius: Double, completion: @escaping ([Person]?, Error?) -> Void) {
        let endpoint = "\(APIConfig.waterfallEndpoint)?lat=\(latitude)&lng=\(longitude)&farFromme=\(radius)"
        guard let url = URL(string: APIConfig.baseURL + endpoint) else {
            completion(nil, NSError(domain: "Invalid URL", code: -1, userInfo: nil))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = UserDefaults.standard.string(forKey: "userToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            print("Token not found. Request might fail.")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, NSError(domain: "No data received", code: -2, userInfo: nil))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                
                // 定義一個臨時結構來解碼每個用戶，包括 user_detail
                struct TempPerson: Decodable {
                    let id: Int
                    let name: String
                    let email: String
                    let lat: String
                    let lng: String
                    let distance: Double
                    let user_detail: [UserDetail]?
                    
                    struct UserDetail: Decodable {
                        let type: String
                        let content: String
                    }
                }
                
                var people: [TempPerson] = []
                
                // 檢查 JSON 是字典還是陣列
                if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // 如果是字典，解碼為 [String: TempPerson]
                    let tempPeopleDict = try decoder.decode([String: TempPerson].self, from: data)
                    people = Array(tempPeopleDict.values)
                } else if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    // 如果是陣列，解碼為 [TempPerson]
                    people = try decoder.decode([TempPerson].self, from: data)
                } else {
                    throw NSError(domain: "Invalid JSON format", code: -3, userInfo: nil)
                }
                
                var result: [Person] = []
                
                for tempPerson in people {
                    var userProfilePhoto: String? = nil
                    var images: [String] = []
                    
                    if let userDetail = tempPerson.user_detail {
                        for i in 1...9 {
                            if let imgDetail = userDetail.first(where: { $0.type == "img\(i)" }) {
                                images.append(imgDetail.content)
                                if i == 1 {
                                    userProfilePhoto = imgDetail.content
                                }
                            }
                        }
                    }
                    
                    let person = Person(
                        id: tempPerson.id,
                        name: tempPerson.name,
                        email: tempPerson.email,
                        lat: tempPerson.lat,
                        lng: tempPerson.lng,
                        distance: tempPerson.distance,
                        UserProfilePhoto: userProfilePhoto,
                        images: images.isEmpty ? nil : images
                    )
                    
                    result.append(person)
                }
                
                completion(result, nil)
            } catch {
                print("Decoding error:", error)
                print(String(data: data, encoding: .utf8)!)
                completion(nil, error)
            }
        }.resume()
    }



    func fetchLocationFromIP(completion: @escaping (CLLocation?, Error?) -> Void) {
        let url = URL(string: "http://ip-api.com/json/")!

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }

            guard let data = data else {
                completion(nil, NSError(domain: "No data received", code: -2, userInfo: nil))
                return
            }
            do {
                        let decoder = JSONDecoder()
                        let locationData = try decoder.decode(IPLocationData.self, from: data)

                        // 创建 CLLocation 对象
                        let location = CLLocation(latitude: locationData.lat, longitude: locationData.lon)

                        // 打印经纬度、国家和地区信息
                        print("Latitude: \(locationData.lat)")
                        print("Longitude: \(locationData.lon)")
                        print("Country: \(locationData.country)")
                        print("Region: \(locationData.regionName)")

                        completion(location, nil)

                    } catch {
                        print("Decoding error:", error)
                        completion(nil, error)
                    }
        }.resume()
    }
    func uploadImage(token: String, imageData: Data, imageType: String, completion: @escaping (Bool, Error?) -> Void) {
        let endpoint = "\(APIConfig.baseURL)/user/file"
        guard let url = URL(string: endpoint) else {
            completion(false, NSError(domain: "Invalid URL", code: -1, userInfo: nil))
            return
        }
        
        // 创建请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // 设置请求头
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") // 添加 token
        
        // 设置请求体
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"type\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(imageType)\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"content\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        // 发送请求
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, error)
                return
            }
            
            // 检查响应状态码
            guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode),
                  let data = data else {
                completion(false, NSError(domain: "API Error", code: -2, userInfo: nil))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   json["status"] as? String == "success" {
                    completion(true, nil)
                } else {
                    completion(false, NSError(domain: "API Error", code: -2, userInfo: nil))
                }
            } catch {
                completion(false, error)
            }
        }.resume()
    }
    
//    以下為聊天室部分code
    func fetchChats(token: String, completion: @escaping (Result<[ChatRoom], Error>) -> Void) {
            guard let url = URL(string: "\(APIConfig.baseURL)/chat") else {
                completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
                return
            }

            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpMethod = "GET"

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let data = data else {
                    completion(.failure(NSError(domain: "No data", code: -1, userInfo: nil)))
                    return
                }

                do {
                    let chats = try JSONDecoder().decode([ChatRoom].self, from: data)
                    completion(.success(chats))
                } catch {
                    print("Error decoding chat rooms:", error)
                    print(String(data: data, encoding: .utf8) ?? "No data")
                    completion(.failure(error))
                }
            }.resume()
        }

        func fetchChatMessages(token: String, roomId: Int, completion: @escaping (Result<[ChatMessage], Error>) -> Void) {
            guard let url = URL(string: "\(APIConfig.baseURL)/chat/\(roomId)") else {
                completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
                return
            }

            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpMethod = "GET"

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let data = data else {
                    completion(.failure(NSError(domain: "No data", code: -1, userInfo: nil)))
                    return
                }

                do {
                    let messages = try JSONDecoder().decode([ChatMessage].self, from: data)
                    completion(.success(messages))
                } catch {
                    print("Error decoding chat messages:", error)
                    print(String(data: data, encoding: .utf8) ?? "No data")
                    completion(.failure(error))
                }
            }.resume()
        }

    func sendMessage(token: String, roomId: Int, content: String, type: String = "text", completion: @escaping (Result<ChatMessage, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/chat/\(roomId)") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        let parameters = "content=\(content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&type=\(type)"
        let postData = parameters.data(using: .utf8)
        request.httpBody = postData

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -1, userInfo: nil)))
                return
            }

            do {
                let message = try JSONDecoder().decode(ChatMessage.self, from: data)
                completion(.success(message))
            } catch {
                print("Error decoding sent message:", error)
                print(String(data: data, encoding: .utf8) ?? "No data")
                completion(.failure(error))
            }
        }.resume()
    }
}
