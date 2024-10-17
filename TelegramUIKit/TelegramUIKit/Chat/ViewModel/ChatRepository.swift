//
//  ChatRepository.swift
//  TelegramUIKit
//
//  Created by surexnx on 11.10.2024.
//

import Foundation
import FirebaseFirestore

protocol ChatRepositoryProtocol {
    func fetchMessages(completion: @escaping ([RawMessage]) -> Void)

    func loadPreviousMessages(_ date: Date, completion: @escaping ([RawMessage]) -> Void)

    func sendMessage(_ message: RawMessage)

    func listenForChat(_ date: Date?)
}

protocol ChatRepositoryDelegate: AnyObject {
    func updateMessage(_ message: RawMessage)

    func removeMessage(_ message: RawMessage)

    func addMessage(_ message: RawMessage)

    func received(messages: [RawMessage])

    func typingStateChanged(to state: TypingState)

    func lastReadIdChanged(to id: String)

    func lastReceivedIdChanged(to id: String)
}

final class ChatRepository: ChatRepositoryProtocol {
    private let concurrentQueue = DispatchQueue(label: "com.example.networkQueue", attributes: .concurrent)

    private let mainQueue: DispatchQueue = .main

    weak var delegate: ChatRepositoryDelegate?

    private var listener: ListenerRegistration?

    private let db = Firestore.firestore()

    private var chat: Chat

    private var userId: String

    init(chat: Chat, userId: String, delegate: ChatRepositoryDelegate? = nil) {
        self.userId = userId
        self.delegate = delegate
        self.chat = chat
    }
    
    func fetchMessages(completion: @escaping ([RawMessage]) -> Void) {
        concurrentQueue.async {
            self.db.collection("rooms").document(self.chat.id).collection("messages")
                .order(by: "ts", descending: true)
                .limit(to: 20)
                .getDocuments { [weak self] snapshot, error in
                    
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("Ошибка получения данных: \(error.localizedDescription)")
                        mainQueue.async {
                            completion([])
                        }
                    }
                    
                    guard let snapshot = snapshot else {
                        print("No matching documents.")
                        mainQueue.async {
                            completion([])
                        }
                        return
                    }
                    
                    let messages = snapshot.documents.compactMap { document -> RawMessage? in
                        return self.convert(document)
                    }
                    mainQueue.async {
                        completion(messages)
                    }
                }
        }
    }

    func loadPreviousMessages(_ date: Date, completion: @escaping ([RawMessage]) -> Void) {
        concurrentQueue.async {

            self.db.collection("rooms").document(self.chat.id).collection("messages")
                .order(by: "ts", descending: true)
                .start(after: [Timestamp(date: date)])
                .limit(to: 20)
                .getDocuments { [weak self] snapshot, error in

                guard let self = self else { return }

                if let error = error {
                    print("Ошибка получения данных: \(error.localizedDescription)")
                    mainQueue.async {
                        completion([])
                    }                }

                guard let snapshot = snapshot else {
                    print("No matching documents.")
                    mainQueue.async {
                        completion([])
                    }
                    return
                }

                    let messages = snapshot.documents.compactMap { document -> RawMessage? in
                        return self.convert(document)
                    }
                    mainQueue.async {
                        completion(messages)
                    }

            }
        }
    }

    func listenForChat(_ date: Date?) {
        guard let date = date else { return }
        let timeStamp = Timestamp(date: date)
        concurrentQueue.async {
            self.listener = self.db.collection("rooms").document(self.chat.id).collection("messages")
                .whereField("ts", isGreaterThan: timeStamp)
                .order(by: "ts", descending: true)
              //  .start(after: [timeStamp])
                .addSnapshotListener { [weak self] querySnapshot, error in
                    guard let self = self else { return }
                    guard let snapshot = querySnapshot else {
                        print("Ошибка получения данных: \(error!)")
                        return
                    }

                    // Обработка изменений в чате
                    snapshot.documentChanges.forEach { diff in
                        let data = diff.document.data()
                        let id = diff.document.documentID

                        if diff.type == .added {

                            let newMessage = self.convert(diff.document)
                            self.mainQueue.async {
                                self.delegate?.addMessage(newMessage)
                            }
                            print("messsage добавлен: \(id) с данными: \(data)")
                        }
                        else if diff.type == .modified {
                            let newMessage = self.convert(diff.document)
                            self.mainQueue.async {
                                self.delegate?.updateMessage(newMessage)
                            }
                            print("message изменен: \(diff.document.documentID)")
                        }
                        else if diff.type == .removed {
                            let newMessage = self.convert(diff.document)
                            self.mainQueue.async {
                                self.delegate?.removeMessage(newMessage)
                            }
                            print("message удален: \(diff.document.documentID)")

                        }
                    }
                }
        }
    }

    func sendMessage(_ message: RawMessage) {
        let timeStamp = Timestamp()

        concurrentQueue.async {

            let roomRef = self.db.collection("rooms").document(self.chat.id)
            let newMesRef = roomRef.collection("messages").document()
            let ts = Timestamp(date: message.date)
            var newMessage = ""
            switch message.data {
            case .text(let text):
                newMessage = text
            case .url(_):
                break
            case .image(_):
                break
            }
            let messageData: [String: Any] = [
                "id": message.id,
                "senderId": self.userId,
                "text": newMessage,
                "ts": ts
            ]
            newMesRef.setData(messageData) { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    print("Ошибка получения данных: \(error.localizedDescription)")
                    return
                }

                roomRef.updateData([
                    "lastMessage": newMessage,
                    "ts": ts
                ]) { error in
                    if let error = error {
                        print("Ошибка при обновлении последнего сообщения: \(error)")
                    }
                }
            }
        }
    }


    private func convert(_ document: QueryDocumentSnapshot) -> RawMessage {
        let data = document.data()

        let id = data["id"] as? String ?? ""
        let userId = data["senderId"] as? String ?? ""
        let text = data["text"] as? String ?? ""
        let status = data["status"] as? Int ?? 0
        let ts = data["ts"] as? Timestamp ?? Timestamp()

        return RawMessage(id: id, date: ts.dateValue(), data: .text(text), userId: userId)
    }
}
