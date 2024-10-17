//
// ChatLayout
// TextMessageView.swift
// https://github.com/ekazaev/ChatLayout
//
// Created by Eugene Kazaev in 2020-2024.
// Distributed under the MIT license.
//
// Become a sponsor:
// https://github.com/sponsors/ekazaev
//

import ChatLayout
import Foundation
import UIKit

final class TextMessageView: UIView, ContainerCollectionViewCellDelegate {
    private var viewPortWidth: CGFloat = 300

    private lazy var textView = MessageTextView()
    private lazy var timeView = MesTimeView()

    private var controller: TextMessageController?

    private var textViewWidthConstraint: NSLayoutConstraint?
    private var textToTimeBottomConstraint: NSLayoutConstraint?
    private var textBottomConstraint: NSLayoutConstraint?
    private var textToTimeTrailingConstraint: NSLayoutConstraint?
    private var textTrailingConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }

    func prepareForReuse() {
        textView.resignFirstResponder()
    }

    // Uncomment this method to test the performance without calculating text cell size using autolayout
    // For the better illustration set DefaultRandomDataProvider.enableRichContent/enableNewMessages
    // to false
//    func preferredLayoutAttributesFitting(_ layoutAttributes: ChatLayoutAttributes) -> ChatLayoutAttributes? {
//        viewPortWidth = layoutAttributes.layoutFrame.width
//        guard let text = controller?.text as NSString? else {
//            return layoutAttributes
//        }
//        let maxWidth = viewPortWidth * Constants.maxWidth
//        var rect = text.boundingRect(with: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude),
//            options: [.usesLineFragmentOrigin, .usesFontLeading],
//            attributes: [NSAttributedString.Key.font: textView.font as Any], context: nil)
//        rect = rect.insetBy(dx: 0, dy: -8)
//        layoutAttributes.size = CGSize(width: layoutAttributes.layoutFrame.width, height: rect.height)
//        setupSize()
//        return layoutAttributes
//    }

    func apply(_ layoutAttributes: ChatLayoutAttributes) {
        viewPortWidth = layoutAttributes.layoutFrame.width
        setupSize()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
    }

    func setup(with controller: TextMessageController) {
        self.controller = controller
        reloadData()
    }

    func reloadData() {
        guard let controller else {
            return
        }
        textView.text = controller.text
        timeView.text = controller.date
        calculateViewHeight()
        UIView.performWithoutAnimation {
            if #available(iOS 13.0, *) {
                textView.textColor = controller.type.isIncoming ? UIColor.label : .systemBackground
                textView.linkTextAttributes = [.foregroundColor: controller.type.isIncoming ? UIColor.systemBlue : .systemGray6,
                                               .underlineStyle: 1]
            } else {
                let color = controller.type.isIncoming ? UIColor.black : .white
                textView.textColor = color
                textView.linkTextAttributes = [.foregroundColor: color,
                                               .underlineStyle: 1]
            }
        }
    }

    private func setupSubviews() {
        layoutMargins = .zero
        translatesAutoresizingMaskIntoConstraints = false
        insetsLayoutMarginsFromSafeArea = false

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.spellCheckingType = .no
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.dataDetectorTypes = .all
        textView.font = .preferredFont(forTextStyle: .body)
        textView.scrollsToTop = false
        textView.bounces = false
        textView.bouncesZoom = false
        textView.showsHorizontalScrollIndicator = false
        textView.showsVerticalScrollIndicator = false
        textView.isExclusiveTouch = true
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        addSubview(textView)

        textViewWidthConstraint = textView.widthAnchor.constraint(lessThanOrEqualToConstant: viewPortWidth)
        textViewWidthConstraint?.isActive = true

        timeView.translatesAutoresizingMaskIntoConstraints = false

        timeView.backgroundColor = .clear

        timeView.font = .preferredFont(forTextStyle: .body)
        timeView.isExclusiveTouch = true
        timeView.font = UIFont.preferredFont(forTextStyle: .body)
        addSubview(timeView)

        NSLayoutConstraint.activate([
            timeView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            timeView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),

            textView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor)
        ])
        textBottomConstraint = textView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        textToTimeBottomConstraint = textView.bottomAnchor.constraint(equalTo: timeView.topAnchor, constant: -10)

        textTrailingConstraint = textView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)
        textToTimeTrailingConstraint = textView.trailingAnchor.constraint(equalTo: timeView.leadingAnchor, constant: -10)
    }

    private func setupSize() {
        UIView.performWithoutAnimation {
            self.textViewWidthConstraint?.constant = viewPortWidth * Constants.maxWidth
            setNeedsLayout()
        }
    }

    private func calculateViewHeight() {

        if textView.text.count < 30 {
            textToTimeTrailingConstraint?.isActive = true
            textTrailingConstraint?.isActive = false
            textToTimeBottomConstraint?.isActive = false
            textBottomConstraint?.isActive = true
        } else {
            textToTimeTrailingConstraint?.isActive = false
            textTrailingConstraint?.isActive = true

            if didTextMoveToNewline(text: textView.text) {
                textToTimeBottomConstraint?.isActive = true
                textBottomConstraint?.isActive = false
            } else {
                textToTimeBottomConstraint?.isActive = false
                textBottomConstraint?.isActive = true
            }
        }

    }

    private func didTextMoveToNewline(text: String) -> Bool {
        let messageBubbleFont = UIFont.systemFont(ofSize: 14.0)
        let maximumTextWidth: CGFloat = 300

        let previousBoundingRect = text.boundingRect(
            with: CGSize(width: maximumTextWidth, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: messageBubbleFont],
            context: nil
        )
        let finalText = "\(text) 10:00PM "
        let boundingRect = finalText.boundingRect(
            with: CGSize(width: maximumTextWidth, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: messageBubbleFont],
            context: nil
        )

        let stringHeight = boundingRect.integral.size.height
        let previousStringHeight = previousBoundingRect.integral.height
        return stringHeight > previousStringHeight
    }
}

extension TextMessageView: AvatarViewDelegate {
    func avatarTapped() {
        if enableSelfSizingSupport {
            layoutMargins = layoutMargins == .zero ? UIEdgeInsets(top: 50, left: 0, bottom: 50, right: 0) : .zero
            setNeedsLayout()
            if let cell = superview(of: UICollectionViewCell.self) {
                cell.contentView.invalidateIntrinsicContentSize()
            }
        }
    }
}

/// UITextView with hacks to avoid selection
private final class MessageTextView: UITextView {
    override var isFocused: Bool {
        false
    }

    override var canBecomeFirstResponder: Bool {
        false
    }

    override var canBecomeFocused: Bool {
        false
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        false
    }
}

private final class MesTimeView: UILabel {
    override var isFocused: Bool {
        false
    }

    override var canBecomeFirstResponder: Bool {
        false
    }

    override var canBecomeFocused: Bool {
        false
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        false
    }
}
