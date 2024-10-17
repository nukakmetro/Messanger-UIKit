//
//  ScrollViewDelegate.swift
//  TelegramView
//
//  Created by surexnx on 20.09.2024.
//

import UIKit

final class ScrollViewDelegate: NSObject, UIScrollViewDelegate {
    let onScrollStart: () -> Void  // Обработчик начала скролла
    let onScrollEnd: () -> Void    // Обработчик завершения скролла

    init(onScrollStart: @escaping () -> Void, onScrollEnd: @escaping () -> Void) {
        self.onScrollStart = onScrollStart
        self.onScrollEnd = onScrollEnd
    }

    // Метод вызывается, когда скролл начинается (перетаскивание)
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        onScrollStart()  // Вызываем обработчик начала скролла
    }

    // Метод вызывается, когда скролл заканчивается с анимацией (например, при инерции)
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        onScrollEnd()  // Вызываем обработчик завершения скролла
    }

    // Метод вызывается, когда скролл завершается после перетаскивания
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            onScrollEnd()  // Вызываем обработчик завершения скролла, если не будет инерции
        }
    }
}
