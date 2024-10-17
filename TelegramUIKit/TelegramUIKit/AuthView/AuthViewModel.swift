//
//  AuthViewModel.swift
//  TelegramView
//
//  Created by surexnx on 24.09.2024.
//
import Combine
import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseAuthCombineSwift

protocol AuthModuleOutput: AnyObject {
    func didFinishAuthorization()
}

enum AuthState {
    case load
    case content
    case error
}

final class AuthViewModel: ObservableObject {

    @Published var firebaseUser: FirebaseAuth.User?
    @Published var state: AuthState = .content

    var db: Firestore
    private var output: AuthModuleOutput?
    private var cancellables = Set<AnyCancellable>()

    init(output: AuthModuleOutput? = nil) {
        self.db = Firestore.firestore()
        self.output = output
    }

    func signUp(email: String, password: String, login: String) {
        state = .load
        Auth.auth().createUser(withEmail: email, password: password)

            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .failure(let error):
                    state = .error
                    print("Ошибка регистрации: \(error.localizedDescription)")
                case .finished:
                    guard let uid = firebaseUser?.uid else { return }

                    let usersReference = db.collection("users").document(uid)

                    let values = ["email": email, "login": login]

                    usersReference.setData(values) { err in
                        if err != nil {
                            return
                        }
                        print("save user in database")
                    }
                    state = .content
                    print("Регистрация завершена")
                }
            }, receiveValue: { authResult in
                self.firebaseUser = authResult.user
                print("Пользователь успешно зарегистрирован: \(authResult.user.email ?? "")")
            })
            .store(in: &cancellables)
    }

    func signIn(email: String, password: String) {
        state = .load
        if email.contains("@") {
            signInWithEmail(email: email, password: password)
        } else {
            getEmailFromLogin(login: email) { email in
                if let email = email {
                    self.signInWithEmail(email: email, password: password)
                }
            }
        }
    }

    private func signInWithEmail(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password)
            .sink(receiveCompletion: {[weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .failure(let error):
                    state = .error
                    print("Ошибка входа: \(error.localizedDescription)")
                case .finished:
                    state = .content
                    print("Вход завершён")
                    UserKey().save(firebaseUser?.uid)
                    output?.didFinishAuthorization()
                }
            }, receiveValue: { authResult in
                self.firebaseUser = authResult.user
                print("Пользователь вошёл: \(authResult.user.email ?? "")")
            })
            .store(in: &cancellables)
    }

    private func getEmailFromLogin(login: String, completion: @escaping (String?) -> Void) {

        db.collection("users").whereField("login", isEqualTo: login).getDocuments { snapshot, error in
            if let error = error {
                completion(nil)
            } else if let snapshot = snapshot, !snapshot.documents.isEmpty {
                let email = snapshot.documents.first?.data()["email"] as? String
                completion(email)
            } else {
                completion(nil)
            }
        }
    }
}
