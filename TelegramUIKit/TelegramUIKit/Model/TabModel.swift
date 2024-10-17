//
//  TabModel.swift
//  TelegramView
//
//  Created by surexnx on 18.09.2024.
//

import SwiftUI

struct TabModel: Identifiable {
    private(set) var id: Tab
    var size: CGSize = .zero
    var minX: CGFloat = .zero

    enum Tab: String, CaseIterable {
        case allChats = "Все чаты"
        case myChat = "Мой чат"
    }
}

