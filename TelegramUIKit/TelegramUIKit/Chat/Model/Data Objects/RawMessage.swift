//
// ChatLayout
// RawMessage.swift
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

struct RawMessage: Hashable {
    enum Data: Hashable {
        case text(String)

        case url(URL)

        case image(ImageMessageSource)
    }

    var id: String

    var date: Date

    var data: Data

    var userId: String

    var status: MessageStatus = .sent
}
