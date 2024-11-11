//
//  DefaultChatsCollectionDataSource.swift
//  TelegramUIKit
//
//  Created by surexnx on 16.10.2024.
//

import ChatLayout
import Foundation
import UIKit

typealias ChatTableCell = ContainerTableViewCell<ChatConteinerView<EditingAccessoryView, ChatInfoView>>

final class DefaultChatsTableDataSource: NSObject, ChatsCollectionDataSource {

    private unowned var editingDelegate: EditingAccessoryControllerDelegate
    private let editNotifier: EditNotifier

    var sections: [ChatsSection] = [] {
        didSet {
            oldSections = oldValue
        }
    }

    private var oldSections: [ChatsSection] = []

    init(editingDelegate: EditingAccessoryControllerDelegate, editNotifier: EditNotifier) {
        self.editingDelegate = editingDelegate
        self.editNotifier = editNotifier

    }

    func prepare(with tableView: UITableView) {
        tableView.register(ChatTableCell.self, forCellReuseIdentifier: ChatTableCell.reuseIdentifier)
    }

    private func createChatCell(tableView: UITableView, indexPath: IndexPath, chat: Chat) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatTableCell.reuseIdentifier, for: indexPath) as! ChatTableCell
        setupChatContainerView(cell.customView, id: chat.id)
        let controller = ChatInfoController(title: chat.title, text: chat.lastMessage, date: chat.date)
        cell.customView.customView.setup(with: controller)
        controller.view = cell.customView.customView
        return cell
    }

    private func setupChatContainerView(_ chatContainerView: ChatConteinerView<EditingAccessoryView, some Any>, id: String) {
        if let accessoryView = chatContainerView.accessoryView {
            editNotifier.add(delegate: accessoryView)
            accessoryView.setIsEditing(editNotifier.isEditing)

            let controller = EditingAccessoryController(messageId: id)
            controller.view = accessoryView
            controller.delegate = editingDelegate
            accessoryView.setup(with: controller)
        }
    }
}

extension DefaultChatsTableDataSource: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].cells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = sections[indexPath.section].cells[indexPath.item]
        switch cell {
            
        case .chat(let chat):
            let cell = createChatCell(tableView: tableView, indexPath: indexPath, chat: chat)
            return cell
        }
    }
}
