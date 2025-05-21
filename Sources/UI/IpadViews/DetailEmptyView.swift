//
//  SwiftUIView 2.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 08/12/24.
//

import SwiftUI

struct DetailEmptyView: View {
    var body: some View {
      VStack {
        if let image = SetUIComponents.shared.ipadEmptyChatView {
          Image(uiImage: image)
        }
        Text("Select a chat or start a new chat to see it here")
      }

    }
}

#Preview {
  DetailEmptyView()
}

extension Color {
  static let myColor = Color(.messageBorder)
  static let primaryprimary = Color(.primaryPrimary)
  static let nuetralWhite = Color(.neutralWhite)
  static let titleColor = Color(.titleBlue)
  static let neutrals100 = Color(.neutrals100)
  static let neutrals800 = Color(.neutrals800)
  static let neutrals600 = Color(.neutrals600)
  static let neutrals400 = Color(.neutrals400)
  static let neutrals1000 = Color(.neutrals1000)
}
