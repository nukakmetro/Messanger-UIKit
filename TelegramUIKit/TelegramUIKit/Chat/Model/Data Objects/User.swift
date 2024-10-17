//
// ChatLayout
// User.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2024.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import DifferenceKit
import Foundation
import UIKit

struct User: Hashable {
    var id: String

    var name: String {
        "Name"
    }
}

extension User: Differentiable {}
