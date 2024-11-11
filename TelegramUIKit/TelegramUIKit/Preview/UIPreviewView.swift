//
//  UIPreviewView.swift
//  TelegramUIKit
//
//  Created by surexnx on 08.11.2024.
//

import Foundation
import UIKit

public class UIPreviewView<CustomView: UIView>: UIView {

    public lazy var customView = CustomView(frame: bounds)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        addSubview(customView)
        insetsLayoutMarginsFromSafeArea = false
        layoutMargins = .zero

        insetsLayoutMarginsFromSafeArea = false
        layoutMargins = .zero

        customView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            customView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            customView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            customView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            customView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor)
        ])
    }
}
