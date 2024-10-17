//
//  ChatsSection.swift
//  TelegramUIKit
//
//  Created by surexnx on 16.10.2024.
//

import DifferenceKit
import Foundation

struct ChatsSection: Hashable {
    var id: Int

    var cells: [ChatsCell]
}

extension ChatsSection: DifferentiableSection {
    public var differenceIdentifier: Int {
        id
    }

    public func isContentEqual(to source: ChatsSection) -> Bool {
        id == source.id
    }

    public var elements: [ChatsCell] {
        cells
    }

    public init<C: Swift.Collection>(source: ChatsSection, elements: C) where C.Element == ChatsCell {
        self.init(id: source.id, cells: Array(elements))
    }
}
