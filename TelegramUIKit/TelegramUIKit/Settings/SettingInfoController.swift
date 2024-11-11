//
//  SettingCellController.swift
//  TelegramUIKit
//
//  Created by surexnx on 23.10.2024.
//

import Foundation
import UIKit

final class SettingInfoController {

    weak var view: SettingInfoView? {
        didSet {
            view?.reloadData()
        }
    }

    private var title: String
    private var leftImage: UIImage?
    private var rightImage: UIImage?
    private var infoImage: UIImage?

    init(title: String, leftImage: UIImage? = nil, rightImage: UIImage? = nil, infoImage: UIImage? = nil) {
        self.title = title
        self.leftImage = leftImage
        self.rightImage = rightImage
        self.infoImage = infoImage
    }

}
