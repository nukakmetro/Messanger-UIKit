//
//  Chat.swift
//  TelegramUIKit
//
//  Created by surexnx on 16.10.2024.
//
import DifferenceKit
import Foundation

struct Chat: Hashable {
    let id: String

    let title: String

    let lastMessage: String

    let date: String
}

extension Chat: Differentiable {
    public var differenceIdentifier: Int {
        id.hashValue
    }

    public func isContentEqual(to source: Chat) -> Bool {
        self == source
    }
}
