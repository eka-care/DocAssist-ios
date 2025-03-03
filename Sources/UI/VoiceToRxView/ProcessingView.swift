//
//  SwiftUIView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 03/03/25.
//

import SwiftUI

struct ProcessingView: View {
  var body: some View {
    HStack {
      Image(.colorDocAssist)
      Text("Analysing conversation...")
        .lineLimit(1)
        .font(Font.custom("Lato", size: 14))
    }
    .padding()
    .frame(width: 250)
    .background(
      LinearGradient(
        gradient: Gradient(colors: [
          Color(red: 245/255, green: 235/255, blue: 255/255),
          Color.white
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
    )
    .clipShape(RoundedRectangle(cornerRadius: 16))
    
  }
}
