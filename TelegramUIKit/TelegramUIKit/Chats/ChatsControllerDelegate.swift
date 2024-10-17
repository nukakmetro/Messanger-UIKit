//
//  ChatsControllerDelegate.swift
//  TelegramUIKit
//
//  Created by surexnx on 15.10.2024.
//

import Foundation

protocol ChatsControllerDelegate: AnyObject {
    func update(with sections: [ChatsSection], requiresIsolatedProcess: Bool)
}
