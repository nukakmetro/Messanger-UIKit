//
//  ChatsCollectionDataSource.swift
//  TelegramUIKit
//
//  Created by surexnx on 15.10.2024.
//

import Foundation
import UIKit

protocol ChatsCollectionDataSource: UITableViewDataSource {
    var sections: [ChatsSection] { get set }

    func prepare(with tableView: UITableView)
}
