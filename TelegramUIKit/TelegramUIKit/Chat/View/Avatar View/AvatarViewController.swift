//
// ChatLayout
// AvatarViewController.swift
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

final class AvatarViewController {
    var image: UIImage? {
        guard bubble == .tailed else {
            return nil
        }
        return UIImage(named: "Eugene")
    }

    private let user: User

    private let bubble: Cell.BubbleType

    weak var view: AvatarView? {
        didSet {
            view?.reloadData()
        }
    }

    init(user: User, bubble: Cell.BubbleType) {
        self.user = user
        self.bubble = bubble
    }
}
