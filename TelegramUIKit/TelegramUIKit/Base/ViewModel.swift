//
//  ViewModel.swift
//  TelegramView
//
//  Created by surexnx on 01.10.2024.
//

import Foundation

protocol ViewModel: ObservableObject {
    associatedtype Intent

    func trigger(_ intent: Intent)
}
