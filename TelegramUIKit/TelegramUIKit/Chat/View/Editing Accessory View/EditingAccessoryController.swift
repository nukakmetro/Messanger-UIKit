//
// ChatLayout
// EditingAccessoryController.swift
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

protocol EditingAccessoryControllerDelegate: AnyObject {
    func deleteMessage(with id: String)
}

final class EditingAccessoryController {
    weak var delegate: EditingAccessoryControllerDelegate?

    weak var view: EditingAccessoryView?

    private let messageId: String

    init(messageId: String) {
        self.messageId = messageId
    }

    func deleteButtonTapped() {
        delegate?.deleteMessage(with: messageId)
    }
}
