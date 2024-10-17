//
//  ChatsViewModel.swift
//  TelegramUIKit
//
//  Created by surexnx on 16.10.2024.
//

import Foundation
import ChatLayout

final class ChatsViewModel: ChatsController {
    
    weak var delegate: ChatsControllerDelegate?

    private var repository: ChatsRepositoryProtocol

    private let dispatchQueue = DispatchQueue(label: "DefaultChatController", qos: .userInteractive)

    private var output: ChatsModuleOutput?

    private var userId: String

    var chats: [RawChat] = []

    init(repository: ChatsRepositoryProtocol, userId: String, output: ChatsModuleOutput? = nil) {
        self.output = output
        self.repository = repository
        self.userId = userId
    }

    func loadInitialChats(completion: @escaping ([ChatsSection]) -> Void) {
        repository.fetchChats { [weak self] rawChats in
            self?.appendConvertingToMessages(rawChats)
            self?.convertToChats { chatsSection in
                self?.listenForChat()
                completion(chatsSection)
            }
        }
    }

    func loadPreviousChats(completion: @escaping ([ChatsSection]) -> Void) {

    }

    func listenForChat() {
//        guard let first = chats.first else { return }
        repository.listenForChat(nil)
    }

    func trigger(_ intent: ChatsIntent) {
        switch intent {
        case .didSelectedItem(let chat):
            output?.didSelectChat(chat)
        }
    }

    private func appendConvertingToMessages(_ rawChats: [RawChat]) {
        var chats = chats
        chats.append(contentsOf: rawChats)
        self.chats = chats.sorted(by: { $0.date.timeIntervalSince1970 < $1.date.timeIntervalSince1970 })
    }

    private func updateSections(_ requiresIsolatedProcess: Bool = false) {
        convertToChats { [weak self] chats in
            self?.delegate?.update(with: chats, requiresIsolatedProcess: requiresIsolatedProcess)
        }
    }

    private func convertToChats(completion: @escaping ([ChatsSection]) -> Void) {
        dispatchQueue.async { [weak self] in
            guard let self else {
                return DispatchQueue.main.async {
                    completion([])
                }
            }
            var chats: [ChatsSection] = []
            var chatCells: [ChatsCell] = []

            self.chats.forEach { chat in
                let chat = Chat(id: chat.id, title: chat.title, lastMessage: chat.lastMessage, date: self.formatDate(date: chat.date))
                chatCells.append(.chat(chat))
            }
            chats.append(.init(id: 0, cells: chatCells))
            DispatchQueue.main.async {
                completion(chats)
            }
        }
    }

    private func formatDate(date: Date) -> String {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()

        if calendar.isDateInToday(date) {
            // Если сегодня, отображаем время
            dateFormatter.dateFormat = "HH:mm"
            return dateFormatter.string(from: date)
        } else if let daysAgo = calendar.dateComponents([.day], from: date, to: Date()).day, daysAgo <= 7 {
            // Если прошло менее 7 дней, выводим день недели
            dateFormatter.dateFormat = "EEEE" // День недели
            dateFormatter.locale = Locale(identifier: "ru_RU") // Локализация для русского языка
            return dateFormatter.string(from: date)
        } else {
            // Если больше 7 дней, выводим дату
            dateFormatter.dateFormat = "dd.MM"
            return dateFormatter.string(from: date)
        }
    }
}
extension ChatsViewModel: ChatsRepositoryDelegate {
    func updateChat(_ chat: RawChat) {
        for index in chats.indices.reversed() {
            if chats[index].id == chat.id {
                chats[index] = chat
                break
            }
        }
        updateSections()
    }
    
    func removeChat(_ chat: RawChat) {
        
    }
    
    func addChat(_ chat: RawChat) {
        chats.append(chat)
        updateSections()
    }
}

extension ChatsViewModel: EditingAccessoryControllerDelegate {
    func deleteMessage(with id: String) {
        chats = Array(chats.filter { $0.id != id })
        updateSections(true)
    }
}
