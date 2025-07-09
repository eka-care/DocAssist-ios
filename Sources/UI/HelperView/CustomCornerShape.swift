//
//  CustomCornerShape.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 09/07/25.
//

import SwiftUI

struct CustomCornerShape: Shape {
  var cornerRadius: CGFloat
  var corners: UIRectCorner
  
  func path(in rect: CGRect) -> Path {
    let path = UIBezierPath(
      roundedRect: rect,
      byRoundingCorners: corners,
      cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
    )
    return Path(path.cgPath)
  }
}

extension View {
  func customCornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
    clipShape(CustomCornerShape(cornerRadius: radius, corners: corners))
  }
  
  func customCornerBorder(_ radius: CGFloat, corners: UIRectCorner, color: Color, lineWidth: CGFloat = 1) -> some View {
    self
      .overlay(
        CustomCornerShape(cornerRadius: radius, corners: corners)
          .stroke(Color(red: 0.83, green: 0.87, blue: 1), lineWidth: 1)
      )
      .clipShape(CustomCornerShape(cornerRadius: radius, corners: corners))
  }
}
