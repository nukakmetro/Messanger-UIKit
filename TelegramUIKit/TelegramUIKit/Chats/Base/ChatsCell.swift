//
//  ChatsCell.swift
//  TelegramUIKit
//
//  Created by surexnx on 16.10.2024.
//

import ChatLayout
import DifferenceKit
import Foundation
import UIKit

enum ChatsCell: Hashable {
    case chat(Chat)
}

extension ChatsCell: Differentiable {
    public var differenceIdentifier: Int {
        switch self {
        case .chat(let chat):
            chat.differenceIdentifier
        }
    }

    public func isContentEqual(to source: ChatsCell) -> Bool {
        self == source
    }
}
