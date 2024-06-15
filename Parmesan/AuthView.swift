//
//  AuthView.swift
//  Parmesan
//
//  Created by 郭粟閣 on 2024/5/26.
//

import SwiftUI

struct AuthView: View {
    @Binding var showingAuth: Bool
    @Binding var isLoggedIn: Bool
    @Binding var user: User?
    @State private var name = ""
    @State private var password = ""
    @State private var email = ""
    @State private var errorMessage = ""
    @State private var showNameInput = false // 控制是否显示用户名输入框
    @State private var showNextButton = false // 控制是否显示下一步按钮
    var refreshPeople: () -> Void // 添加 refreshPeople 函数作为参数

    
    var body: some View {
        VStack {
            Image("capybara")
                .resizable()
                .frame(maxWidth: 100, maxHeight: 100)
                .cornerRadius(24)
                .padding(.bottom, 24)
            Text("Parmesan Cheese")
                .font(.title)
                .bold()
            if showNameInput { // 只有在 showNameInput 为 true 时显示用户名输入框
                TextField("Name", text: $name)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
            // 邮箱和密码输入框使用 conditional rendering 控制显示
            if !showNextButton { // 只有在 showNextButton 为 false 时显示邮箱和密码输入框
                TextField("Email", text: $email)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .textInputAutocapitalization(.never)
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            // 登录注册按钮的 HStack
            HStack {
                if showNextButton { // 只有在 showNextButton 为 true 时显示下一步按钮
                    Button("Next") {
                        register()
                    }
                    .padding()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(8)
                } else {
                    Button("Register") {
                        // 点击 Register 按钮时，显示用户名输入框和下一步按钮
                        showNameInput = true
                        showNextButton = true
                    }
                    .padding()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(8)
                }

                Button("Login") {
                    Task {
                        do {
                            try await login()
                        } catch {
                            errorMessage = "Login failed: \(error.localizedDescription)"
                        }
                    }
                }
                .padding()
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .cornerRadius(8)
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
            Button("Cancel") {
                showingAuth = false
            }
            .padding()
            .foregroundColor(.red)
        }
    }

    func register() {
        // 在这里发送注册请求
        Task {
            do {
                try await APIService.shared.register(name: name, email: email, password: password)
                print("Register successful! User Info: \(user)")
                showingAuth = false
                isLoggedIn = true
                user = user
                errorMessage = ""
            } catch {
                errorMessage = "Registration failed: \(error.localizedDescription)"
            }
        }
    }

    func login() async throws {
        let response = try await APIService.shared.login(email: email, password: password)
        print("Login successful! Token: \(response.token)")
        showingAuth = false
        isLoggedIn = true
        if let token = response.token {
            try await fetchUserInfo(token: token)
        }
        print("login. now perform refresh people")
        refreshPeople()
    }

    func fetchUserInfo(token: String) async throws {
        let user = try await APIService.shared.fetchUserInfo(token: token)
        print("User Info: \(user)")
        self.user = user
    }
}
