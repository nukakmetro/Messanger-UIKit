//
//  MessageContainerView.swift
//  TelegramUIKit
//
//  Created by surexnx on 01.11.2024.
//

import Foundation
import UIKit
import ChatLayout

protocol MainMessageSwipeHandler {
    func updateSwipeCompletionRate(_ newSwipeCompletionRate: CGFloat)
}

final class DefaultMessageContainerView<AccessoryViewFactory: StaticViewFactory, MainView: UIView & MainMessageSwipeHandler>: UIView, UIGestureRecognizerDelegate {

    private lazy var stackView = UIStackView(frame: bounds)

    /// An accessory view.
    public lazy var accessoryView: AccessoryViewFactory.View? = AccessoryViewFactory.buildView(within: bounds)

    /// Main view.
    public var customView: MainView {
        internalContentView.customView
    }

    weak var swipeDelegate: SwipeReplyDelegate?

    private lazy var panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleRevealPan(_:)))
        gesture.delegate = self
        return gesture
    }()

    /// An alignment of the contained views within the `MessageContainerView`,
    public var alignment: ChatItemAlignment = .fullWidth {
        didSet {
            switch alignment {
            case .leading:
                internalContentView.flexibleEdges = [.trailing]
            case .trailing:
                internalContentView.flexibleEdges = [.leading]
            case .center:
                internalContentView.flexibleEdges = [.leading, .trailing]
            case .fullWidth:
                internalContentView.flexibleEdges = []
            }
        }
    }

    private lazy var internalContentView = EdgeAligningView<MainView>(frame: bounds)

    /// Initializes and returns a newly allocated view object with the specified frame rectangle.
    /// - Parameter frame: The frame rectangle for the view, measured in points. The origin of the frame is relative
    ///   to the superview in which you plan to add it.
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
        addGestureRecognizer(panGesture)
    }

    /// Returns an object initialized from data in a given unarchiver.
    /// - Parameter coder: An unarchiver object.
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }

    private func setupSubviews() {
        translatesAutoresizingMaskIntoConstraints = false
        insetsLayoutMarginsFromSafeArea = false
        layoutMargins = .zero
        addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = .zero

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)
        ])

        if let accessoryView {
            stackView.addArrangedSubview(accessoryView)
            accessoryView.translatesAutoresizingMaskIntoConstraints = false
        }

        internalContentView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(internalContentView)
    }
    
    // MARK: - UIGestureRecognizerDelegate

    @objc
    private func handleRevealPan(_ gesture: UIPanGestureRecognizer) {
        swipeDelegate?.swipeHandler(gesture) { [weak self] newCompletionRate in
            guard let self = self else { return }
            customView.updateSwipeCompletionRate(newCompletionRate)
        }
    }
}
