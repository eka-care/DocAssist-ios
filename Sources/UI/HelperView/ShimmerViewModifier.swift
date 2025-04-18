//
//  ShimmerViewModifier.swift
//  DocAssist-ios
//
//  Created by Brunda B on 18/04/25.
//

import SwiftUI

struct ShimmerViewModifier: ViewModifier {
  @State private var isAnimating = false
  
  func body(content: Content) -> some View {
    content
      .overlay(
        GeometryReader { geometry in
          LinearGradient(
            gradient: Gradient(colors: [
              .clear,
              Color(red: 217/255, green: 217/255, blue: 217/255).opacity(0.7),
              .clear
            ]),
            startPoint: .leading,
            endPoint: .trailing
          )
          .frame(width: geometry.size.width * 3)
          .offset(x: self.isAnimating ? geometry.size.width : -geometry.size.width * 2)
        }
      )
      .mask(content)
      .onAppear {
        withAnimation(Animation.linear(duration: 2.0).repeatForever(autoreverses: false)) {
          self.isAnimating = true
        }
      }
  }
}


extension View {
  func shimmer() -> some View {
    modifier(ShimmerViewModifier())
  }
}
