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
