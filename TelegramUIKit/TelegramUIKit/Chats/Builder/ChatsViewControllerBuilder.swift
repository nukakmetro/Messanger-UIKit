//
//  ChatsViewBuilder.swift
//  TelegramUIKit
//
//  Created by surexnx on 16.10.2024.
//

import Foundation
import UIKit

struct ChatsViewControllerBuilder {
    func build(output: ChatsModuleOutput, userId: String) -> UIViewController {
        let repository = ChatsRepository(userId: userId)
        let chatsController = ChatsViewModel(repository: repository, userId: userId, output: output)
        repository.delegate = chatsController

        let editNotifier = EditNotifier()
        let dataSource = DefaultChatsTableDataSource(editingDelegate: chatsController, editNotifier: editNotifier)


        let chatsViewController = ChatsViewController(dataSource: dataSource, chatsContoller: chatsController, editNotifier: editNotifier)
        chatsController.delegate = chatsViewController
        return chatsViewController
    }
}
