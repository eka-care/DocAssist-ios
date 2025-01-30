//
//  SwiftUIView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 28/01/25.
//

import SwiftUI

struct ImagePreviewCell: View {
  let imageUrl: URL
  let onDelete: () -> Void
  
  var body: some View {
    ZStack(alignment: .topTrailing) {
      AsyncImage(url: imageUrl) { image in
        image
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: 66, height: 66)
          .clipped()
      } placeholder: {
        ProgressView()
      }
      Button(action: onDelete) {
        Image(systemName: "xmark.circle.fill")
          .foregroundColor(.white)
          .background(Color.black.opacity(0.5))
          .clipShape(Circle())
      }
      .padding(4)
    }
  }
}
