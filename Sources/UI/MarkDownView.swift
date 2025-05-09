//
//  MarkDownView.swift
//  DocAssist-ios
//
//  Created by Brunda B on 09/05/25.
//

import SwiftUI
import MarkdownUI

struct MarkDownView: View {
  var text: String
  
    var body: some View {
      VStack {
        Markdown(text)
          .padding()
        Spacer()
      }
      .navigationTitle("Medical Notes")
    }
}


