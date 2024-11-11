//
//  SettingsViewCell.swift
//  TelegramUIKit
//
//  Created by surexnx on 23.10.2024.
//

import UIKit

final class SettingInfoView: UIView {

    private var controller: SettingInfoController?
    private let dateWidth: CGFloat = 70
    private let avatarSize: CGFloat = 50
    private lazy var titleLabel = UILabel()
    private lazy var dateLabel = UILabel()
    private lazy var textLabel = UILabel()
    private lazy var avatar = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        avatar.layer.cornerRadius = avatar.bounds.width / 2
    }

    func setup(with controller: SettingInfoController) {
        self.controller = controller
        reloadData()
    }

    private func setupSubviews() {
        layoutMargins = .zero
        translatesAutoresizingMaskIntoConstraints = false
        insetsLayoutMarginsFromSafeArea = false

        titleLabel.numberOfLines = 1
        textLabel.numberOfLines = 2
        textLabel.textAlignment = .left
        titleLabel.textAlignment = .left
        dateLabel.textAlignment = .right
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        avatar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        addSubview(dateLabel)
        addSubview(textLabel)
        addSubview(avatar)

        NSLayoutConstraint.activate([

            avatar.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            avatar.heightAnchor.constraint(equalToConstant: avatarSize),
            avatar.widthAnchor.constraint(equalToConstant: avatarSize),
            avatar.centerYAnchor.constraint(equalTo: layoutMarginsGuide.centerYAnchor),

            dateLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            dateLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            dateLabel.widthAnchor.constraint(equalToConstant: dateWidth),

            titleLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 20),
            titleLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: dateLabel.leadingAnchor, constant: -20),

            textLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            textLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 20),
            textLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: -20),
            textLabel.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, constant: -10)

            ])
    }

    func reloadData() {
        guard let controller else {
            return
        }
        
    }

}
