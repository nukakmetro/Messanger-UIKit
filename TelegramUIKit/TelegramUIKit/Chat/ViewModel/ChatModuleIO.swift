//
//  ChatModuleIO.swift
//  TelegramUIKit
//
//  Created by surexnx on 12.10.2024.
//

import Foundation

protocol ChatModuleInput: AnyObject {
    func load(chat: Chat)
}

protocol ChatModuleOutput {
    func didLoad(input: ChatModuleInput)
}
