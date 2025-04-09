//
//  SwiftUIView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 06/01/25.
//

import SwiftUI

struct SearchBar: View {
  @Binding var text: String
  @State private var isEditing: Bool = false
  
  var body: some View {
    HStack {
      ZStack {
        RoundedRectangle(cornerRadius: 10)
          .foregroundStyle(Color.gray.opacity(0.1))
          .frame(height: 35)
        
        HStack {
          Image(systemName: "magnifyingglass")
            .foregroundColor(.gray)
            .padding(.leading, 8)
          
          TextField("Search", text: $text, onEditingChanged: { editing in
            withAnimation {
              isEditing = editing
            }
          })
          .padding(.vertical, 8)
          .padding(.horizontal, 4)
          .scrollDismissesKeyboard(.automatic)
          
          if !text.isEmpty {
            Button(action: {
              text = ""
            }) {
              Image(systemName: "xmark.circle.fill")
                .foregroundColor(.gray)
                .padding(.trailing, 8)
            }
          }
        }
      }
    }
    .padding(.horizontal, 16)
  }
}
