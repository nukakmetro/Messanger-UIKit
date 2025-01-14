//
// ChatLayout
// ChatViewControllerBuilder.swift
//
// Created by Eugene Kazaev in 2020-2024.
// Distributed under the MIT license.

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
                                                         reloadDelegate: messageController,
                                                         editingDelegate: messageController)


        let messageViewController = ChatViewController(chatController: messageController, dataSource: dataSource, editNotifier: editNotifier)
        messageController.delegate = messageViewController
        dataSource.swipeDelegate = messageViewController
        return messageViewController
    }
}
