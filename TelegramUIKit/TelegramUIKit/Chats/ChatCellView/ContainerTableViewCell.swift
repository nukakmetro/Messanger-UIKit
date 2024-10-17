//
//  ContainerTableViewCell.swift
//  TelegramUIKit
//
//  Created by surexnx on 17.10.2024.
//

import Foundation
import UIKit

public final class ContainerTableViewCell<CustomView: UIView>: UITableViewCell {

    public static var reuseIdentifier: String {
        String(describing: self)
    }

    public lazy var customView = CustomView(frame: bounds)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        contentView.addSubview(customView)
        insetsLayoutMarginsFromSafeArea = false
        layoutMargins = .zero

        contentView.insetsLayoutMarginsFromSafeArea = false
        contentView.layoutMargins = .zero

        customView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            customView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            customView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            customView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            customView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor)
        ])
    }
}
