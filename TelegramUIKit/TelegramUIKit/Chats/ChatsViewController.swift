//
//  ChatsViewController.swift
//  TelegramUIKit
//
//  Created by surexnx on 14.10.2024.
//

import UIKit
import ChatLayout
import DifferenceKit

final class ChatsViewController: UIViewController {
    
    private enum ReactionTypes {
        case delayedUpdate
    }

    private enum InterfaceActions {
        case changingKeyboardFrame
        case changingContentInsets
        case changingFrameSize
        case sendingMessage
        case scrollingToTop
        case scrollingToBottom
        case showingPreview
        case showingAccessory
        case updatingCollectionInIsolation
    }

    private enum ControllerActions {
        case loadingInitialMessages
        case loadingPreviousMessages
        case updatingCollection
    }
    private var currentInterfaceActions: SetActor<Set<InterfaceActions>, ReactionTypes> = SetActor()
    private var currentControllerActions: SetActor<Set<ControllerActions>, ReactionTypes> = SetActor()
    private var tableView: UITableView!
    private lazy var searchButton = UIButton()

    private let dataSource: ChatsCollectionDataSource
    private let chatsController: ChatsController
    private let editNotifier: EditNotifier

    private var isScrolledToTheBeginning = false
    private var translationX: CGFloat = 0
    private var currentOffset: CGFloat = 0
    private var previousContentOffsetY: CGFloat = 0
    private var tableViewTopAnchor: NSLayoutConstraint?
    private var searchButtonHeightAnchor: NSLayoutConstraint?
    private let minConstraintConstant: CGFloat = 0
    private let maxConstraintConstant: CGFloat = 40

    private var selectedCell: IndexPath?

    fileprivate var isUserInitiatedScrolling: Bool {
        tableView.isDragging || tableView.isDecelerating
    }

    init(dataSource: ChatsCollectionDataSource, chatsContoller: ChatsController, editNotifier: EditNotifier) {
        self.chatsController = chatsContoller
        self.editNotifier = editNotifier
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Chats"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Изм.", style: .plain, target: self, action: #selector(ChatsViewController.setEditNotEdit))
        tableView = UITableView(frame: .zero)
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        tableView.addGestureRecognizer(longPressGesture)

        view.addSubview(tableView)
        tableView.alwaysBounceVertical = true
        tableView.dataSource = dataSource
        tableView.delegate = self
        tableView.keyboardDismissMode = .interactive
        tableView.isPrefetchingEnabled = false
        tableView.contentInsetAdjustmentBehavior = .always
        if #available(iOS 13.0, *) {
            tableView.automaticallyAdjustsScrollIndicatorInsets = true
        }

        if #available(iOS 16.0, *),
           enableSelfSizingSupport {
            tableView.selfSizingInvalidation = .enabled
        }

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.frame = view.bounds
//        tableViewTopAnchor = tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0)
//        tableViewTopAnchor?.isActive = true
        setupSearchButton()
        searchButtonHeightAnchor = searchButton.heightAnchor.constraint(equalToConstant: 40)
        searchButtonHeightAnchor?.isActive = true
        NSLayoutConstraint.activate([
            searchButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            searchButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            searchButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),

            tableView.topAnchor.constraint(equalTo: searchButton.bottomAnchor, constant: 5),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0)
        ])
        tableView.backgroundColor = .systemBackground
        tableView.showsHorizontalScrollIndicator = false
        dataSource.prepare(with: tableView)

        currentControllerActions.options.insert(.loadingInitialMessages)
//        chatsController.loadInitialChats { sections in
//            self.currentControllerActions.options.remove(.loadingInitialMessages)
//            self.processUpdates(with: sections, animated: true, requiresIsolatedProcess: false)
//        }

        chatsController.listenForChat()

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: tableView)

        guard let indexPath = tableView.indexPathForRow(at: location) else { return }
        self.selectedCell = indexPath

        if gesture.state == .began {

            let cell = tableView.cellForRow(at: indexPath)
            guard let cell = cell else  { return }
            var chat: Chat?
            let cellInfo = dataSource.sections[indexPath.section].cells[indexPath.row]
            switch cellInfo {
                case .chat(let data):
                chat = data
            }
            guard let chat = chat else { return }
            guard let userId = UserKey().get() else { return }

            let preview = ChatPreviewControllerBuilder().build(chat: chat, userId: userId)
            preview.delegate = self
            preview.modalPresentationStyle = .custom
            preview.transitioningDelegate = self
            present(preview, animated: true)

        } else if gesture.state == .ended || gesture.state == .cancelled {
            let cell = tableView.cellForRow(at: indexPath)
        }
    }

    private func processUpdates(with sections: [ChatsSection], animated: Bool = true, requiresIsolatedProcess: Bool, completion: (() -> Void)? = nil) {
            dataSource.sections = sections
            return
        tableView.reloadData()
    }

    @objc
    private func setEditNotEdit() {
        isEditing = !isEditing
        editNotifier.setIsEditing(isEditing, duration: .animated(duration: 0.25))
        navigationItem.rightBarButtonItem?.title = isEditing ? "Done" : "Edit"
        tableView.setNeedsLayout()
    }

    private func setupSearchButton() {
        searchButton.setTitle("Search", for: .normal)
        searchButton.configuration = .bordered()
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        searchButton.setTitleColor(UIColor.black.withAlphaComponent(0.5), for: .normal)
        view.addSubview(searchButton)
    }
}

extension ChatsViewController: UIScrollViewDelegate {
    public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        guard scrollView.contentSize.height > 0,
              !currentInterfaceActions.options.contains(.showingAccessory),
              !currentInterfaceActions.options.contains(.showingPreview),
              !currentInterfaceActions.options.contains(.scrollingToTop),
              !currentInterfaceActions.options.contains(.scrollingToBottom) else {
            return false
        }
        currentInterfaceActions.options.insert(.scrollingToTop)
        return true
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard let searchButtonHeightAnchor = searchButtonHeightAnchor else { return }
        var newConstraintConstant: CGFloat = 0
        if searchButtonHeightAnchor.constant > 20 {
            newConstraintConstant = maxConstraintConstant
        } else {
            newConstraintConstant = minConstraintConstant
        }
        UIView.animate(withDuration: 0.4) {
            searchButtonHeightAnchor.constant = newConstraintConstant
        }

    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        if currentControllerActions.options.contains(.updatingCollection), tableView.isDragging {
//            // Interrupting current update animation if user starts to scroll while batchUpdate is performed. It helps to
//            // avoid presenting blank area if user scrolls out of the animation rendering area.
//            UIView.performWithoutAnimation {
//                self.tableView.performBatchUpdates({}, completion: { _ in
//                    let context = ChatLayoutInvalidationContext()
//                    context.invalidateLayoutMetrics = false
//                })
//            }
//        }
//        guard !currentControllerActions.options.contains(.loadingInitialMessages),
//              !currentControllerActions.options.contains(.loadingPreviousMessages),
//              !currentInterfaceActions.options.contains(.scrollingToTop),
//              !currentInterfaceActions.options.contains(.scrollingToBottom) else {
//            return
//        }

//        if scrollView.contentOffset.y <= -scrollView.adjustedContentInset.top + scrollView.bounds.height {
//            loadPreviousMessages()
//        }

        let currentContentOffsetY = scrollView.contentOffset.y
            let scrollDiff = currentContentOffsetY - previousContentOffsetY

            // Верхняя граница начала bounce эффекта
            let bounceBorderContentOffsetY = -scrollView.contentInset.top

            let contentMovesUp = scrollDiff > 0 && currentContentOffsetY > bounceBorderContentOffsetY
            let contentMovesDown = scrollDiff < 0 && currentContentOffsetY < bounceBorderContentOffsetY

        let currentConstraintConstant = searchButtonHeightAnchor!.constant
            var newConstraintConstant = currentConstraintConstant

            if contentMovesUp {
                // Уменьшаем константу констрэйнта
                newConstraintConstant = max(currentConstraintConstant - scrollDiff, minConstraintConstant)
            } else if contentMovesDown {
                // Увеличиваем константу констрэйнта
                newConstraintConstant = min(currentConstraintConstant - scrollDiff, maxConstraintConstant)
            }

            // Меняем высоту и запрещаем скролл, только в случае изменения константы
            if newConstraintConstant != currentConstraintConstant {

                switch newConstraintConstant {
                case 40:
                    searchButton.setTitleColor(UIColor.black.withAlphaComponent(1), for: .normal)
                case 30:
                    searchButton.setTitleColor(UIColor.black.withAlphaComponent(0.7), for: .normal)
                case 20:
                    searchButton.setTitleColor(UIColor.black.withAlphaComponent(0.3), for: .normal)
                default:
                    break
                }

                searchButtonHeightAnchor?.constant = newConstraintConstant

                searchButton.isHidden = newConstraintConstant == 0

                scrollView.contentOffset.y = previousContentOffsetY
            }

            // Процент завершения анимации
            let animationCompletionPercent = (maxConstraintConstant - currentConstraintConstant) / (maxConstraintConstant - minConstraintConstant)

            previousContentOffsetY = scrollView.contentOffset.y
    }
}

extension ChatsViewController: UITableViewDelegate {
    @available(iOS 13.0, *)
    private func preview(for configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let identifier = configuration.identifier as? String else {
            return nil
        }
        let components = identifier.split(separator: "|")
        guard components.count == 2,
              let sectionIndex = Int(components[0]),
              let itemIndex = Int(components[1]),
              let cell = tableView.cellForRow(at: IndexPath(item: itemIndex, section: sectionIndex)) as? ChatTableCell else {
            return nil
        }
        guard let userId = UserKey().get() else { return nil }

        let item = dataSource.sections[0].cells[itemIndex]
        switch item {

        case .chat(let chat):
            let parameters = UIPreviewParameters()
            let previewView = ChatPreviewControllerBuilder().build(chat: chat, userId: userId)

            return UITargetedPreview(view: previewView.view, parameters: parameters)
        }
    }
//    func tableView(_ tableView: UITableView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
//        preview(for: configuration)
//    }
//
//    func tableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
//        preview(for: configuration)
//    }
//
//    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
//        guard !currentInterfaceActions.options.contains(.showingPreview),
//              !currentControllerActions.options.contains(.updatingCollection) else {
//            return nil
//        }
//        let item = dataSource.sections[indexPath.section].cells[indexPath.item]
//        switch item {
//        case .chat(let chat):
//            let actions = [UIAction(title: "Copy", image: nil, identifier: nil) { body in
//                let pasteboard = UIPasteboard.general
//            }]
//            let menu = UIMenu(title: "", children: actions)
//            // Custom NSCopying identifier leads to the crash. No other requirements for the identifier to avoid the crash are provided.
//            let identifier: NSString = "\(indexPath.section)|\(indexPath.item)" as NSString
//            currentInterfaceActions.options.insert(.showingPreview)
//            return UIContextMenuConfiguration(identifier: identifier, previewProvider: nil, actionProvider: { _ in menu })
//        }
//    }

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let editAction = UIContextualAction(style: .normal, title: "Редактировать") { (action, view, completionHandler) in
            print("Редактирование ячейки \(indexPath.row)")
            completionHandler(true)
        }
        editAction.backgroundColor = .blue

        let pinAction = UIContextualAction(style: .normal, title: "Закрепить") { (action, view, completionHandler) in
            print("Закрепление ячейки \(indexPath.row)")
            completionHandler(true)
        }
        pinAction.backgroundColor = .orange

        return UISwipeActionsConfiguration(actions: [editAction, pinAction])
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Удалить") { (action, view, completionHandler) in
            print("Удаление ячейки \(indexPath.row)")
            completionHandler(true)
        }

        let moreAction = UIContextualAction(style: .normal, title: "Еще") { (action, view, completionHandler) in
            print("Дополнительные действия для ячейки \(indexPath.row)")
            completionHandler(true)
        }
        moreAction.backgroundColor = .gray
        return UISwipeActionsConfiguration(actions: [deleteAction, moreAction])
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = dataSource.sections[indexPath.section].cells[indexPath.item]
        switch cell {

        case .chat(let chat):
            chatsController.trigger(.didSelectedItem(chat))
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
extension ChatsViewController: ChatsControllerDelegate {

    func notifyIsScrolledToTheBeginning() {
        isScrolledToTheBeginning = true
    }

    func update(with sections: [ChatsSection], requiresIsolatedProcess: Bool) {
        processUpdates(with: sections, animated: true, requiresIsolatedProcess: requiresIsolatedProcess)
    }
}
extension ChatsViewController: UIViewControllerTransitioningDelegate {

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return DimmingPresentationController(presentedViewController: presented, presenting: presenting)
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let selectedCell = selectedCell,
              let selectedFrame = tableView.cellForRow(at: selectedCell)?.frame else { return nil }
        return PresentingAnimator(originFrame: selectedFrame)
    }
}

extension ChatsViewController: UIPreviewControllerDelegate {
    func dismiss() {
        dismiss(animated: true)
    }
}
