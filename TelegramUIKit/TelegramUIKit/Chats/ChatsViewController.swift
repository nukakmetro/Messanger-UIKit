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

    private func processUpdates(with sections: [ChatsSection], animated: Bool = true, requiresIsolatedProcess: Bool, completion: (() -> Void)? = nil) {
//        guard isViewLoaded else {
            dataSource.sections = sections
            return
//        }
        tableView.reloadData()
//        guard currentInterfaceActions.options.isEmpty else {
//            let reaction = SetActor<Set<InterfaceActions>, ReactionTypes>.Reaction(type: .delayedUpdate,
//                                                                                   action: .onEmpty,
//                                                                                   executionType: .once,
//                                                                                   actionBlock: { [weak self] in
//                guard let self else {
//                    return
//                }
//                processUpdates(with: sections, animated: animated, requiresIsolatedProcess: requiresIsolatedProcess, completion: completion)
//            })
//            currentInterfaceActions.add(reaction: reaction)
//            return
//        }

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
