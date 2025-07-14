//
//  PdfBodyView.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 13/07/25.
//

import SwiftUI
import EkaUI
import MarkdownUI

struct PdfBodyView: View {
  
  let text: String
  
  var body: some View {
    VStack {
      Markdown(text)
    }
    .padding(.horizontal, EkaSpacing.spacingM)
    .padding(.top, EkaSpacing.spacingM)
  }
}
