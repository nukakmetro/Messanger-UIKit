//
//  AuthView.swift
//  TelegramView
//
//  Created by surexnx on 24.09.2024.
//

import SwiftUI

struct AuthView: View {
    @ObservedObject private var viewModel: AuthViewModel
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var currentPage: Int = 0
    @State private var login: String = ""
    @State private var isLoading: Bool = false

    init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            PageControl(pages: ["Вход", "Регистрация"], currentPage: $currentPage)

            if currentPage == 1 {
                TextField("login", text: $login)
                    .padding()
                    .background(.gray)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                .black,
                                lineWidth: 2
                            )
                    )
                    .padding()
            }


            TextField(currentPage == 0 ? "Email or login" : "Email", text: $email)
                .padding()
                .background(.gray)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            .black,
                            lineWidth: 2
                        )
                )
                .padding()

            TextField("Password", text: $password)
                .padding()
                .background(.gray)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            .black,
                            lineWidth: 2
                        )
                )
                .padding()
            Button {
                if currentPage == 1 {
                    viewModel.signUp(email: email, password: password, login: login)
                } else {
                    viewModel.signIn(email: email, password: password)
                }
            } label: {
                if currentPage == 1 {
                    Text("Sign Up")
                } else {
                    Text("Sign In")
                }
            }
            .buttonStyle(.bordered)
        }
        .disabled(viewModel.state == .load)
        .onChange(of: viewModel.state, { _, _ in
            if viewModel.state == .load {
                isLoading = true
            } else if viewModel.state != .load {
                isLoading = false
            }
        })
        .background(.white)
        .overlay {
            LoadingView(show: $isLoading)
        }
    }
}

//#Preview {
//    AuthView(viewModel: AuthViewModel(isPresented: .constant(false)))
//}
