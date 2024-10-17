//
//  PageControl.swift
//  TelegramView
//
//  Created by surexnx on 09.09.2024.
//

import SwiftUI

struct PageControl: View {
    @State var pages: [String]
    @Binding var currentPage: Int
    
    var body: some View {

        ScrollView(.horizontal) {
            HStack {
                
                ForEach(0..<pages.count, id: \.self) { index in
                    Button {
                        withAnimation {
                            currentPage = index
                        }
                    } label: {
                        Text(pages[index])
                            .tint(currentPage == index ? .black : .gray)
                            .font(Font.system(size: 18))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
    }
}

