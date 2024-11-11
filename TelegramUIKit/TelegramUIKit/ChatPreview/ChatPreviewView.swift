//
//  ChatPreviewController.swift
//  TelegramUIKit
//
//  Created by surexnx on 28.10.2024.
//

import ChatLayout
import DifferenceKit
import Foundation
import InputBarAccessoryView
import UIKit

final class ChatPreviewView: UIViewController {
    let enableSelfSizingSupport = false

    let enableReconfigure = false
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

    override var canBecomeFirstResponder: Bool {
        true
    }

    private var isScrolledToTheBeginning = false

    private var currentInterfaceActions: SetActor<Set<InterfaceActions>, ReactionTypes> = SetActor()
    private var currentControllerActions: SetActor<Set<ControllerActions>, ReactionTypes> = SetActor()

    private var collectionView: UICollectionView!
    private var chatLayout = CollectionViewChatLayout()
    private let chatController: ChatController
    private let dataSource: ChatCollectionDataSource
    private var animator: ManualAnimator?

    private var translationX: CGFloat = 0
    private var currentOffset: CGFloat = 0

    init(chatController: ChatController,
         dataSource: ChatCollectionDataSource) {
        self.chatController = chatController
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }

        chatLayout.settings.interItemSpacing = 8
        chatLayout.settings.interSectionSpacing = 8
        chatLayout.settings.additionalInsets = UIEdgeInsets(top: 8, left: 5, bottom: 8, right: 5)
        chatLayout.keepContentOffsetAtBottomOnBatchUpdates = true
        chatLayout.processOnlyVisibleItemsOnAnimatedBatchUpdates = false
        chatLayout.keepContentAtBottomOfVisibleArea = true

        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: chatLayout)
        view.addSubview(collectionView)
        collectionView.alwaysBounceVertical = true
        collectionView.dataSource = dataSource
        chatLayout.delegate = dataSource
        collectionView.keyboardDismissMode = .interactive

        collectionView.isPrefetchingEnabled = false

        collectionView.contentInsetAdjustmentBehavior = .always
        if #available(iOS 13.0, *) {
            collectionView.automaticallyAdjustsScrollIndicatorInsets = true
        }

        if #available(iOS 16.0, *),
           enableSelfSizingSupport {
            collectionView.selfSizingInvalidation = .enabled
            chatLayout.supportSelfSizingInvalidation = true
        }

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.frame = view.bounds
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0)
        ])
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        dataSource.prepare(with: collectionView)

        currentControllerActions.options.insert(.loadingInitialMessages)
        chatController.loadInitialMessages { sections in
            self.currentControllerActions.options.remove(.loadingInitialMessages)
            self.processUpdates(with: sections, animated: true, requiresIsolatedProcess: false)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        collectionView.collectionViewLayout.invalidateLayout()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard isViewLoaded else {
            return
        }
        currentInterfaceActions.options.insert(.changingFrameSize)
        let positionSnapshot = chatLayout.getContentOffsetSnapshot(from: .bottom)
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.setNeedsLayout()
        coordinator.animate(alongsideTransition: { _ in
            // Gives nicer transition behaviour
            // self.collectionView.collectionViewLayout.invalidateLayout()
            self.collectionView.performBatchUpdates(nil)
        }, completion: { _ in
            if let positionSnapshot,
               !self.isUserInitiatedScrolling {
                self.chatLayout.restoreContentOffset(with: positionSnapshot)
            }
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.currentInterfaceActions.options.remove(.changingFrameSize)
        })
        super.viewWillTransition(to: size, with: coordinator)
    }
}

extension ChatPreviewView: UIScrollViewDelegate {
    public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        guard scrollView.contentSize.height > 0,
              !currentInterfaceActions.options.contains(.showingAccessory),
              !currentInterfaceActions.options.contains(.showingPreview),
              !currentInterfaceActions.options.contains(.scrollingToTop),
              !currentInterfaceActions.options.contains(.scrollingToBottom) else {
            return false
        }
        // Blocking the call of loadPreviousMessages() as UIScrollView behaves the way that it will scroll to the top even if we keep adding
        // content there and keep changing the content offset until it actually reaches the top. So instead we wait until it reaches the top and initiate
        // the loading after.
        currentInterfaceActions.options.insert(.scrollingToTop)
        return true
    }

    public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        guard !currentControllerActions.options.contains(.loadingInitialMessages),
              !currentControllerActions.options.contains(.loadingPreviousMessages) else {
            return
        }
        currentInterfaceActions.options.remove(.scrollingToTop)
        loadPreviousMessages()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if currentControllerActions.options.contains(.updatingCollection), collectionView.isDragging {
            // Interrupting current update animation if user starts to scroll while batchUpdate is performed. It helps to
            // avoid presenting blank area if user scrolls out of the animation rendering area.
            UIView.performWithoutAnimation {
                self.collectionView.performBatchUpdates({}, completion: { _ in
                    let context = ChatLayoutInvalidationContext()
                    context.invalidateLayoutMetrics = false
                    self.collectionView.collectionViewLayout.invalidateLayout(with: context)
                })
            }
        }
        guard !currentControllerActions.options.contains(.loadingInitialMessages),
              !currentControllerActions.options.contains(.loadingPreviousMessages),
              !currentInterfaceActions.options.contains(.scrollingToTop),
              !currentInterfaceActions.options.contains(.scrollingToBottom) else {
            return
        }

        if scrollView.contentOffset.y <= -scrollView.adjustedContentInset.top + scrollView.bounds.height {
            loadPreviousMessages()
        }
    }

    private func loadPreviousMessages() {
        guard isScrolledToTheBeginning == false else { return }

        currentControllerActions.options.insert(.loadingPreviousMessages)
        chatController.loadPreviousMessages { [weak self] sections in
            guard let self else {
                return
            }
            // Reloading the content without animation just because it looks better is the scrolling is in process.
            let animated = !isUserInitiatedScrolling
            processUpdates(with: sections, animated: animated, requiresIsolatedProcess: false) {
                self.currentControllerActions.options.remove(.loadingPreviousMessages)
            }
        }
    }

    fileprivate var isUserInitiatedScrolling: Bool {
        collectionView.isDragging || collectionView.isDecelerating
    }

    func scrollToBottom(completion: (() -> Void)? = nil) {
        // I ask content size from the layout because on IOs 12 collection view contains not updated one
        let contentOffsetAtBottom = CGPoint(x: collectionView.contentOffset.x,
                                            y: chatLayout.collectionViewContentSize.height - collectionView.frame.height + collectionView.adjustedContentInset.bottom)

        guard contentOffsetAtBottom.y > collectionView.contentOffset.y else {
            completion?()
            return
        }

        let initialOffset = collectionView.contentOffset.y
        let delta = contentOffsetAtBottom.y - initialOffset
        if abs(delta) > chatLayout.visibleBounds.height {
            // See: https://dasdom.dev/posts/scrolling-a-collection-view-with-custom-duration/
            animator = ManualAnimator()
            animator?.animate(duration: TimeInterval(0.25), curve: .easeInOut) { [weak self] percentage in
                guard let self else {
                    return
                }
                collectionView.contentOffset = CGPoint(x: collectionView.contentOffset.x, y: initialOffset + (delta * percentage))
                if percentage == 1.0 {
                    animator = nil
                    let positionSnapshot = ChatLayoutPositionSnapshot(indexPath: IndexPath(item: 0, section: 0), kind: .footer, edge: .bottom)
                    chatLayout.restoreContentOffset(with: positionSnapshot)
                    currentInterfaceActions.options.remove(.scrollingToBottom)
                    completion?()
                }
            }
        } else {
            currentInterfaceActions.options.insert(.scrollingToBottom)
            UIView.animate(withDuration: 0.25, animations: { [weak self] in
                self?.collectionView.setContentOffset(contentOffsetAtBottom, animated: true)
            }, completion: { [weak self] _ in
                self?.currentInterfaceActions.options.remove(.scrollingToBottom)
                completion?()
            })
        }
    }
}

extension ChatPreviewView: ChatControllerDelegate {

    func notifyIsScrolledToTheBeginning() {
        isScrolledToTheBeginning = true
    }

    func update(with sections: [Section], requiresIsolatedProcess: Bool) {
        let requiresIsolatedProcess = chatLayout.keepContentAtBottomOfVisibleArea == true && chatLayout.collectionViewContentSize.height < chatLayout.visibleBounds.height ? true : requiresIsolatedProcess
        processUpdates(with: sections, animated: true, requiresIsolatedProcess: requiresIsolatedProcess)
    }

    private func processUpdates(with sections: [Section], animated: Bool = true, requiresIsolatedProcess: Bool, completion: (() -> Void)? = nil) {
        guard isViewLoaded else {
            dataSource.sections = sections
            return
        }

        guard currentInterfaceActions.options.isEmpty else {
            let reaction = SetActor<Set<InterfaceActions>, ReactionTypes>.Reaction(type: .delayedUpdate,
                                                                                   action: .onEmpty,
                                                                                   executionType: .once,
                                                                                   actionBlock: { [weak self] in
                                                                                       guard let self else {
                                                                                           return
                                                                                       }
                                                                                       processUpdates(with: sections, animated: animated, requiresIsolatedProcess: requiresIsolatedProcess, completion: completion)
                                                                                   })
            currentInterfaceActions.add(reaction: reaction)
            return
        }

        func process() {
            // If there is a big amount of changes, it is better to move that calculation out of the main thread.
            // Here is on the main thread for the simplicity.
            let changeSet = StagedChangeset(source: dataSource.sections, target: sections).flattenIfPossible()

            guard !changeSet.isEmpty else {
                completion?()
                return
            }

            if requiresIsolatedProcess {
                chatLayout.processOnlyVisibleItemsOnAnimatedBatchUpdates = true
                currentInterfaceActions.options.insert(.updatingCollectionInIsolation)
            }
            currentControllerActions.options.insert(.updatingCollection)
            collectionView.reload(using: changeSet,
                                  interrupt: { changeSet in
                                      guard changeSet.sectionInserted.isEmpty else {
                                          return true
                                      }
                                      return false
                                  },
                                  onInterruptedReload: {
                                      let positionSnapshot = ChatLayoutPositionSnapshot(indexPath: IndexPath(item: 0, section: sections.count - 1), kind: .footer, edge: .bottom)
                                      self.collectionView.reloadData()
                                      // We want so that user on reload appeared at the very bottom of the layout
                                      self.chatLayout.restoreContentOffset(with: positionSnapshot)
                                  },
                                  completion: { _ in
                                      DispatchQueue.main.async {
                                          self.chatLayout.processOnlyVisibleItemsOnAnimatedBatchUpdates = false
                                          if requiresIsolatedProcess {
                                              self.currentInterfaceActions.options.remove(.updatingCollectionInIsolation)
                                          }
                                          completion?()
                                          self.currentControllerActions.options.remove(.updatingCollection)
                                      }
                                  },
                                  setData: { data in
                                      self.dataSource.sections = data
                                  })
        }

        if animated {
            process()
        } else {
            UIView.performWithoutAnimation {
                process()
            }
        }
    }
}
