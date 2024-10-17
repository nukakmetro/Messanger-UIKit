//
//  LoadingView.swift
//  TelegramView
//
//  Created by surexnx on 02.10.2024.
//

import SwiftUI

struct LoadingView: View {

    @Binding var show: Bool

    var body: some View {
        ZStack {
            if show {
                Group {
                    Rectangle()
                        .fill(.black.opacity(0.25))
                        .ignoresSafeArea()
                    ProgressView()
                        .padding(15)
                        .background(.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: show)
    }
}

//#Preview {
//    @Binding var show: Bool = true
//    LoadingView(show: show)
//}
