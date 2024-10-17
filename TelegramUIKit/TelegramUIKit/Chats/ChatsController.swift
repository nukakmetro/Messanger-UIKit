//
//  ChatController.swift
//  TelegramUIKit
//
//  Created by surexnx on 15.10.2024.
//

import Foundation

protocol ChatsController {
    func loadInitialChats(completion: @escaping ([ChatsSection]) -> Void)

    func loadPreviousChats(completion: @escaping ([ChatsSection]) -> Void)

    func listenForChat()
    
    func trigger(_ intent: ChatsIntent)
}

enum ChatsIntent {
    case didSelectedItem(Chat)
}
