//
//  ChatsRepository.swift
//  TelegramUIKit
//
//  Created by surexnx on 16.10.2024.
//

import Foundation
import FirebaseFirestore

protocol ChatsRepositoryProtocol {
    func fetchChats(completion: @escaping ([RawChat]) -> Void)

    func loadPreviousChats(_ date: Date, completion: @escaping ([RawChat]) -> Void)

    func listenForChat(_ date: Date?)
}

protocol ChatsRepositoryDelegate: AnyObject {
    func updateChat(_ chat: RawChat)

    func removeChat(_ chat: RawChat)

    func addChat(_ chat: RawChat)
}

final class ChatsRepository: ChatsRepositoryProtocol {

    private let concurrentQueue = DispatchQueue(label: "com.example.network", attributes: .concurrent)

    private let mainQueue: DispatchQueue = .main

    weak var delegate: ChatsRepositoryDelegate?

    private var listener: ListenerRegistration?

    private let db = Firestore.firestore()

    private var userId: String

    init(userId: String, delegate: ChatsRepositoryDelegate? = nil) {
        self.userId = userId
        self.delegate = delegate
    }

    func fetchChats(completion: @escaping ([RawChat]) -> Void) {
        concurrentQueue.async {

            self.db.collection("rooms").whereField("participants", arrayContains: self.userId)
                .order(by: "ts", descending: true)
                .getDocuments { [weak self] snapshot, error in
                    guard let self = self else { return }
                    if let error {
                        print("Error fetching chat rooms: \(error)")
                        return
                    }
                    guard let snapshot else { return }
                    let chatsTuple = snapshot.documents

                    let dispatchGroup = DispatchGroup()
                    var chats: [RawChat] = []
                    for chat in chatsTuple {
                        dispatchGroup.enter()
                        convert(chat) { chat in
                            chats.append(chat)
                            dispatchGroup.leave()
                        }
                    }
                    dispatchGroup.notify(queue: .main) {
                        completion(chats)
                    }
                }
        }
    }

    func loadPreviousChats(_ date: Date, completion: @escaping ([RawChat]) -> Void) {
        
    }

    func listenForChat(_ date: Date?) {
//        guard let date = date else { return }
//        let timeStamp = Timestamp(date: date)

        concurrentQueue.async {
            self.listener = self.db.collection("rooms")
                .whereField("participants", arrayContains: self.userId)
//                .whereField("ts", isGreaterThan: timeStamp)
                .addSnapshotListener { [weak self] querySnapshot, error in
                    guard let self = self else { return }

                    guard let snapshot = querySnapshot else {
                        print("Ошибка получения данных: \(error!)")
                        return
                    }

                    // Обработка изменений в чате
                    snapshot.documentChanges.forEach { diff in
                        let chatData = diff.document.data()
                        let chatID = diff.document.documentID

                        if diff.type == .added {
                            self.convert(diff.document) { chat in
                                self.delegate?.addChat(chat)
                                print("Чат добавлен: \(chatID) с данными: \(chatData)")
                            }
                        }
                        else if diff.type == .modified {
                            self.convert(diff.document) { chat in
                                self.delegate?.updateChat(chat)
                                print("Чат изменен: \(diff.document.documentID)")
                            }
                        }
                        else if diff.type == .removed {
                            self.convert(diff.document) { chat in
                                self.delegate?.removeChat(chat)
                                print("Чат удален: \(diff.document.documentID)")
                            }
                        }
                    }
                }
        }
    }


    private func convert(_ document: QueryDocumentSnapshot, completion: @escaping ((RawChat) -> Void)) {
        let data = document.data()

        let isDialog = data["isDialog"] as? Bool ?? false
        let id = document.documentID
        let lastMessage = data["lastMessage"] as? String ?? ""
        let ts = data["ts"] as? Timestamp ?? Timestamp()

        if isDialog {
            let participants = data["participants"] as? [String] ?? []
            let recipientsId = participants.first { $0 != userId }
            var username = "Получатель"
            getUserName(id: recipientsId) { result in
                guard let result = result else { return }
                username = result
                let chat = RawChat(id: id, title: username, lastMessage: lastMessage, date: ts.dateValue())
                completion(chat)
            }

        } else {
            let title = data["title"] as? String ?? ""
            let chat = RawChat(id: id, title: title, lastMessage: lastMessage, date: ts.dateValue())
            completion(chat)
        }
    }

    private func getUserName(id: String?, completion: @escaping ((String?) -> Void)) {

        guard let id = id else { return }
        db.collection("users").document(id).getDocument { snapshot, error in
            if let error = error {
                print("Ошибка получения данных: \(error.localizedDescription)")
                return
            }

            guard let snapshot = snapshot else {
                print("No matching documents.")
                return
            }

            let username = snapshot.data()?["login"] as? String
            completion(username)
        }
    }

}
