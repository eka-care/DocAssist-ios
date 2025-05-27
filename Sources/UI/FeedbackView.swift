//
//  FeedbackView.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 27/05/25.
//

import SwiftUI

struct FeedbackView: View {
  var showFeedback: Bool
  var feedbackText: String
  
  var body: some View {
    if showFeedback {
      VStack {
        Text(feedbackText)
          .padding()
          .background(.black)
          .foregroundColor(.white)
          .clipShape(RoundedRectangle(cornerRadius: 50))
          .transition(.scale)
          .zIndex(1)
          .animation(.easeInOut, value: showFeedback)
          .padding(.top, 60 )
        Spacer()
      }
    }
  }
}
