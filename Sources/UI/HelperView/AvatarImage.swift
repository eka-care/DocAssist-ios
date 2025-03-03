//
//  SwiftUIView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 03/03/25.
//

import SwiftUI

struct AvatarImage: View {
  let image: UIImage?
  let frameSize: CGFloat
  let cornerRadius: CGFloat?
  let foregroundColor: Color?

  var body: some View {
    if let image = image {
      Image(uiImage: image)
        .resizable()
        .scaledToFit()
        .frame(width: frameSize)
        .cornerRadius(cornerRadius ?? 0)
        .foregroundStyle(foregroundColor ?? Color.clear)
    }
  }
}

struct BotAvatarImage: View {
  var body: some View {
    AvatarImage(
      image: SetUIComponents.shared.chatIcon,
      frameSize: 20,
      cornerRadius: nil,
      foregroundColor: nil
    )
  }
}

struct UserAvatarImage: View {
  var body: some View {
    AvatarImage(
      image: SetUIComponents.shared.userIcon,
      frameSize: 35,
      cornerRadius: 15,
      foregroundColor: Color.gray
    )
  }
}

struct LoadingView: View {
  var body: some View {
    HStack {
      BotAvatarImage()
        .padding()
      ProgressView()
      Spacer()
    }
  }
}
