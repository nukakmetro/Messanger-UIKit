//
//  ChatCellController.swift
//  TelegramUIKit
//
//  Created by surexnx on 16.10.2024.
//

import Foundation
import UIKit

final class ChatInfoController {

    weak var view: ChatInfoView? {
        didSet {
            view?.reloadData()
        }
    }

    let title: String
    let text: String
    let date: String
    let avatar: UIImage?

    init(title: String, text: String, date: String, avatar: UIImage? = nil) {
        self.title = title
        self.text = text
        self.date = date
        self.avatar = avatar == nil ? UIImage(systemName: "person") : avatar
    }
}
