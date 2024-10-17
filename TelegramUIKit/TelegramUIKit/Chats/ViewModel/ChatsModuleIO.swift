//
//  ChatsModuleIO.swift
//  TelegramUIKit
//
//  Created by surexnx on 16.10.2024.
//

import Foundation

protocol ChatsModuleOutput: AnyObject {
    func didSelectChat(_ chat: Chat)
}
