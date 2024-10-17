//
// ChatLayout
// TextMessageController.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2024.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import Foundation

final class TextMessageController {
    weak var view: TextMessageView? {
        didSet {
            view?.reloadData()
        }
    }

    let text: String

    let date: String

    let type: MessageType

    private let bubbleController: BubbleController

    init(text: String, type: MessageType, bubbleController: BubbleController, date: Date) {
        self.text = text
        self.type = type
        self.date = MessageDateFormatter.shared.string(from: date)
        self.bubbleController = bubbleController
    }
}
