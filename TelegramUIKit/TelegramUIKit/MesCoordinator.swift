//
//  MesCoordinator.swift
//  TelegramView
//
//  Created by surexnx on 25.09.2024.
//

import UIKit
import SwiftUI
import FirebaseAuth

final class MesCoordinator {
    
    weak var navigationController: UINavigationController?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        navigationController.pushViewController(UIViewController(), animated: false)
    }

    func start() {
        if let user = Auth.auth().currentUser {
            UserKey().save(user.uid)
            showChatsScreen()
        } else {
            let viewModel = AuthViewModel(output: self)
            let controller = UIHostingController(rootView: AuthView(viewModel: viewModel))
            navigationController?.setViewControllers([controller], animated: false)
        }

    }

//    private func showSendMessageScreen() {
//        let controller = UIHostingController(rootView: SendMesView(viewModel: SendMesViewModel()))
//        navigationController?.present(controller, animated: true)
//    }

    private func showChatsScreen() {
        guard let userId = UserKey().get() else { return }

        let controller = ChatsViewControllerBuilder().build(output: self, userId: userId)

        //navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.setViewControllers([controller], animated: false)
    }

    private func showChatScreen(chat: Chat, userId: String) {
        let controller = ChatViewControllerBuilder().build(chat: chat, userId: userId)
        self.navigationController?.setNavigationBarHidden(false, animated: false)

        // navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.pushViewController(controller, animated: true)
    }

    private func dismiss() {
        navigationController?.dismiss(animated: true)
    }

    private func popView() {
        navigationController?.popViewController(animated: true)
    }

}

//extension MesCoordinator: SendMesViewModuleOuput {
//
//    func processedTappedUser(user: UserModel) {
//        dismiss()
//    }
//}

extension MesCoordinator: ChatsModuleOutput {
    
    func didSelectChat(_ chat: Chat) {
        guard let userId = UserKey().get() else { return }
        showChatScreen(chat: chat, userId: userId)
    }
}

//extension MesCoordinator: ChatViewModuleOuput {
//    func processedTappedBack() {
//        popView()
//    }
//
//    func load(_ input: any ChatViewModuleinput) {
//        chatInput = input
//    }
//}

extension MesCoordinator: AuthModuleOutput {
    func didFinishAuthorization() {
        showChatsScreen()
    }
}
