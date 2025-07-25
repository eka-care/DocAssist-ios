//
//  SwiftUIView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 28/01/25.
//

import SwiftUI

struct ImagePreviewCell: View {
  let imageUrl: String
  let imageId: Int
  let onDelete: (_ Index: Int) -> Void
  var body: some View {
    ZStack(alignment: .topTrailing) {
      let completeUrl = DocAssistFileHelper.getDocumentDirectoryURL().appendingPathComponent(imageUrl)
      AsyncImage(url: completeUrl) { image in
        image
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: 66, height: 66)
          .clipped()
          .cornerRadius(10)
      } placeholder: {
        ProgressView()
      }
      Button {
        onDelete(imageId)
      } label: {
        Image(systemName: "xmark.circle.fill")
          .foregroundColor(.white)
          .background(Color.black.opacity(0.5))
          .clipShape(Circle())
          .padding(10)
      }
      .contentShape(Rectangle())
    }
  }
}

