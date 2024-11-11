//
//  ChatPreviewBuilder.swift
//  TelegramUIKit
//
//  Created by surexnx on 28.10.2024.
//

import Foundation
import UIKit

struct ChatPreviewControllerBuilder {
    func build(chat: Chat, userId: String) -> ChatPreviewController {
        let repository = ChatRepository(chat: chat, userId: userId)
        let messageController = ChatViewModel(repository: repository, chat: chat, userId: userId)
        repository.delegate = messageController
        let editNotifier = EditNotifier()
        let swipeNotifier = SwipeNotifier()
        let dataSource = DefaultChatCollectionDataSource(editNotifier: editNotifier,
                                                         reloadDelegate: messageController,
                                                         editingDelegate: messageController)


        let messageViewController = ChatPreviewController(chatController: messageController, dataSource: dataSource)
        messageController.delegate = messageViewController
        return messageViewController
    }
}
