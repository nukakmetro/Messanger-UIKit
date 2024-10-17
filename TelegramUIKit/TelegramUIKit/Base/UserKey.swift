//
//  UserKey.swift
//  TelegramUIKit
//
//  Created by surexnx on 12.10.2024.
//

import KeychainSwift

final class UserKey {

    func save(_ value: String?) {
        guard let value = value else { return }
        KeychainSwift().set(value, forKey: "user")
    }

    func get() -> String? {
        KeychainSwift().get("user")
    }
}
