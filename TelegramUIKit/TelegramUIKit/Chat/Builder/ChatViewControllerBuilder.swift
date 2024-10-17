//
// ChatLayout
// ChatViewControllerBuilder.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2024.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation
import UIKit

struct ChatViewControllerBuilder {
    func build(chat: Chat, userId: String) -> UIViewController {
        let repository = ChatRepository(chat: chat, userId: userId)
        let messageController = ChatViewModel(repository: repository, chat: chat, userId: userId)
        repository.delegate = messageController
        let editNotifier = EditNotifier()
        let swipeNotifier = SwipeNotifier()
        let dataSource = DefaultChatCollectionDataSource(editNotifier: editNotifier,
                                                         swipeNotifier: swipeNotifier,
                                                         reloadDelegate: messageController,
                                                         editingDelegate: messageController)


        let messageViewController = ChatViewController(chatController: messageController, dataSource: dataSource, editNotifier: editNotifier, swipeNotifier: swipeNotifier)
        messageController.delegate = messageViewController
        return messageViewController
    }
}
