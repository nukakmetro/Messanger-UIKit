//
//  ChatControllerViewModel.swift
//  TelegramUIKit
//
//  Created by surexnx on 10.10.2024.
//

import Foundation
import ChatLayout

final class ChatViewModel: ChatController {
    
    weak var delegate: ChatControllerDelegate?

    private var repository: ChatRepositoryProtocol

    private var typingState: TypingState = .idle

    private let dispatchQueue = DispatchQueue(label: "DefaultChatController", qos: .userInteractive)

    private var lastReadUUID: String?

    private var lastReceivedUUID: String?

    private var chat: Chat

    private var userId: String

    var messages: [RawMessage] = []

    var sentMessage: [String] = []

    init(repository: ChatRepositoryProtocol, chat: Chat, userId: String) {
        self.repository = repository
        self.chat = chat
        self.userId = userId
    }

    func loadInitialMessages(completion: @escaping ([Section]) -> Void) {
        repository.fetchMessages { messages in
            self.appendConvertingToMessages(messages)
            self.markAllMessagesAsReceived {
                self.markAllMessagesAsRead {
                    self.propagateLatestMessages {[weak self] sections in
                        self?.listenForChat()
                        completion(sections)
                    }
                }
            }
        }
    }

    func loadPreviousMessages(completion: @escaping ([Section]) -> Void) {
        print("load previous")
        guard let date = messages.first?.date else { return completion([]) }

        repository.loadPreviousMessages(date) {[weak self] messages in
            guard let self = self else { return }
            if messages.count < 20 {
                self.delegate?.notifyIsScrolledToTheBeginning()
            }
            self.appendConvertingToMessages(messages)
            self.markAllMessagesAsReceived {
                self.markAllMessagesAsRead {
                    self.propagateLatestMessages { sections in
                        completion(sections)
                    }
                }
            }
        }
    }

    func listenForChat(){
        repository.listenForChat(messages.last?.date)
    }

    func sendMessage(_ data: Message.Data, completion: @escaping ([Section]) -> Void) {
        let newMessage = RawMessage(id: UUID().uuidString, date: Date(), data: convert(data), userId: userId)
        repository.sendMessage(newMessage)
        messages.append(newMessage)
        sentMessage.append(newMessage.id)
        propagateLatestMessages { sections in
            completion(sections)
        }
    }

    private func appendConvertingToMessages(_ rawMessages: [RawMessage]) {
        var messages = messages
        messages.append(contentsOf: rawMessages)
        self.messages = messages.sorted(by: { $0.date.timeIntervalSince1970 < $1.date.timeIntervalSince1970 })
    }

    private func propagateLatestMessages(completion: @escaping ([Section]) -> Void) {
        var lastMessageStorage: Message?
        dispatchQueue.async { [weak self] in
            guard let self else {
                return
            }
            let messagesSplitByDay = messages
                .map { Message(id: $0.id,
                               date: $0.date,
                               data: self.convert($0.data),
                               owner: User(id: $0.userId),
                               type: $0.userId == self.userId ? .outgoing : .incoming,
                               status: $0.status) }
                .reduce(into: [[Message]]()) { result, message in
                    guard var section = result.last,
                          let prevMessage = section.last else {
                        let section = [message]
                        result.append(section)
                        return
                    }
                    if Calendar.current.isDate(prevMessage.date, equalTo: message.date, toGranularity: .hour) {
                        section.append(message)
                        result[result.count - 1] = section
                    } else {
                        let section = [message]
                        result.append(section)
                    }
                }

            let cells = messagesSplitByDay.enumerated().map { index, messages -> [Cell] in
                var cells: [Cell] = Array(messages.enumerated().map { index, message -> [Cell] in
                    let bubble: Cell.BubbleType
                    if index < messages.count - 1 {
                        let nextMessage = messages[index + 1]
                        bubble = nextMessage.owner == message.owner ? .normal : .tailed
                    } else {
                        bubble = .tailed
                    }
                    guard message.type != .outgoing else {
                        lastMessageStorage = message
                        return [.message(message, bubbleType: bubble)]
                    }

                    let titleCell = Cell.messageGroup(MessageGroup(id: message.id, title: "\(message.owner.name)", type: message.type))

                    if let lastMessage = lastMessageStorage {
                        if lastMessage.owner != message.owner {
                            lastMessageStorage = message
                            return [titleCell, .message(message, bubbleType: bubble)]
                        } else {
                            lastMessageStorage = message
                            return [.message(message, bubbleType: bubble)]
                        }
                    } else {
                        lastMessageStorage = message
                        return [titleCell, .message(message, bubbleType: bubble)]
                    }
                }.joined())

                if let firstMessage = messages.first {
                    let dateCell = Cell.date(DateGroup(id: firstMessage.id, date: firstMessage.date))
                    cells.insert(dateCell, at: 0)
                }

                if self.typingState == .typing,
                   index == messagesSplitByDay.count - 1 {
                    cells.append(.typingIndicator)
                }

                return cells // Section(id: sectionTitle.hashValue, title: sectionTitle, cells: cells)
            }.joined()

            DispatchQueue.main.async { [weak self] in
                guard self != nil else {
                    return
                }
                completion([Section(id: 0, title: "Loading...", cells: Array(cells))])
            }
        }
    }

    private func convert(_ data: Message.Data) -> RawMessage.Data {
        switch data {
        case let .url(url, isLocallyStored: _):
            .url(url)
        case let .image(source, isLocallyStored: _):
            .image(source)
        case let .text(text):
            .text(text)
        }
    }

    private func convert(_ data: RawMessage.Data) -> Message.Data {
        switch data {
        case let .url(url):
            let isLocallyStored: Bool
            if #available(iOS 13, *) {
                isLocallyStored = metadataCache.isEntityCached(for: url)
            } else {
                isLocallyStored = true
            }
            return .url(url, isLocallyStored: isLocallyStored)
        case let .image(source):
            func isPresentLocally(_ source: ImageMessageSource) -> Bool {
                switch source {
                case .image:
                    true
                case let .imageURL(url):
                    imageCache.isEntityCached(for: CacheableImageKey(url: url))
                }
            }
            return .image(source, isLocallyStored: isPresentLocally(source))
        case let .text(text):
            return .text(text)
        }
    }

    private func repopulateMessages(requiresIsolatedProcess: Bool = false) {
        propagateLatestMessages { sections in
            self.delegate?.update(with: sections, requiresIsolatedProcess: requiresIsolatedProcess)
        }
    }
}

extension ChatViewModel: ChatRepositoryDelegate {
    
    func addMessage(_ message: RawMessage) {
        if let index = sentMessage.firstIndex(of: message.id) {
            sentMessage.remove(at: index)
        } else {
            messages.append(message)
            repopulateMessages()
        }
    }
    
    func updateMessage(_ message: RawMessage) {
        for mes in messages.indices.reversed() {
            if messages[mes].id == message.id {
                messages[mes] = message
                break
            }
        }
        repopulateMessages()
    }
    
    func removeMessage(_ message: RawMessage) {
    }
    
    func received(messages: [RawMessage]) {
        appendConvertingToMessages(messages)
        markAllMessagesAsReceived {
            self.markAllMessagesAsRead {
                self.repopulateMessages()
            }
        }
    }

    func typingStateChanged(to state: TypingState) {
        typingState = state
        repopulateMessages()
    }

    func lastReadIdChanged(to id: String) {
        lastReadUUID = id
        markAllMessagesAsRead {
            self.repopulateMessages()
        }
    }

    func lastReceivedIdChanged(to id: String) {
        lastReceivedUUID = id
        markAllMessagesAsReceived {
            self.repopulateMessages()
        }
    }

    func markAllMessagesAsReceived(completion: @escaping () -> Void) {
        guard let lastReceivedUUID else {
            completion()
            return
        }
        dispatchQueue.async { [weak self] in
            guard let self else {
                return
            }
            var finished = false
            messages = messages.map { message in
                guard !finished, message.status != .received, message.status != .read else {
                    if message.id == lastReceivedUUID {
                        finished = true
                    }
                    return message
                }
                var message = message
                message.status = .received
                if message.id == lastReceivedUUID {
                    finished = true
                }
                return message
            }
            DispatchQueue.main.async {
                completion()
            }
        }
    }

    func markAllMessagesAsRead(completion: @escaping () -> Void) {
        guard let lastReadUUID else {
            completion()
            return
        }
        dispatchQueue.async { [weak self] in
            guard let self else {
                return
            }
            var finished = false
            messages = messages.map { message in
                guard !finished, message.status != .read else {
                    if message.id == lastReadUUID {
                        finished = true
                    }
                    return message
                }
                var message = message
                message.status = .read
                if message.id == lastReadUUID {
                    finished = true
                }
                return message
            }
            DispatchQueue.main.async {
                completion()
            }
        }
    }
}

extension ChatViewModel: ReloadDelegate {
    func reloadMessage(with id: String) {
        repopulateMessages()
    }
}

extension ChatViewModel: EditingAccessoryControllerDelegate {
    func deleteMessage(with id: String) {
        messages = Array(messages.filter { $0.id != id })
        repopulateMessages(requiresIsolatedProcess: true)
    }
}


