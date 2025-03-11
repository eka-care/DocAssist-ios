//
//  SwiftUIView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 03/03/25.
//

import SwiftUI

struct DocSuggestion: View {
  
  var image: UIImage
  var title: String
  var subTitle: String
  
  init(image: UIImage, title: String, subTitle: String) {
    self.image = image
    self.title = title
    self.subTitle = subTitle
  }
  
  var body: some View {
    
    HStack(alignment: .top, spacing: 12) {
      Spacer()
      Image(uiImage: image)
        .frame(width: 24)
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .foregroundStyle(Color.neutrals600)
          .font(.custom("Lato-Bold", size: 16))
          .frame(maxWidth: .infinity, alignment: .leading)
        Text(subTitle)
          .foregroundStyle(Color.neutrals600)
          .font(.custom("Lato-Regular", size: 13))
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .frame(width: 260)
      Spacer()
    }
  }
}
