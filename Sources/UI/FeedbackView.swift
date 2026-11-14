//
//  FeedbackView.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 27/05/25.
//
//  A short confirmation toast (copied, feedback sent) that floats at the top.
//

import SwiftUI

struct FeedbackView: View {
  var showFeedback: Bool
  var feedbackText: String

  var body: some View {
    VStack {
      if showFeedback {
        Label(feedbackText, systemImage: "checkmark.circle.fill")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.primary)
          .padding(.horizontal, 16)
          .padding(.vertical, 10)
          .chatGlass(in: Capsule(), interactive: false)
          .transition(.move(edge: .top).combined(with: .opacity))
      }
      Spacer()
    }
    .padding(.top, 8)
    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showFeedback)
    .allowsHitTesting(false)
  }
}
