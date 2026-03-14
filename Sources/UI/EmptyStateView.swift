//
//  SwiftUIView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 10/02/25.
//

import SwiftUI

struct EmptyStateView: View {
  var body: some View {
    VStack {
      Divider()
      HStack {
        Text(SetUIComponents.shared.isPatientApp ?? false ? "Start a new chat with Health Bot to-" : "Start a new chat with Doc Assist to-")
          .fontWeight(.bold)
          .font(.custom("Lato-Bold", size: 18))
          .foregroundStyle(SetUIComponents.shared.emptyHistoryFgColor ?? Color.gray)
          .padding(.leading, 20)
          .padding(.top, 16)
        Spacer()
      }
      HStack {
        VStack(alignment: .leading, spacing: 12) {
          Text("💊 Confirm drug interactions")
          Text("🥬 Generate diet charts")
          Text("🏋️‍♀️ Get lifestyle advice for a patient")
          Text("📃 Generate medical certificate templates")
          Text("and much more..")
        }
        .foregroundStyle(SetUIComponents.shared.emptyHistoryFgColor ?? Color.gray)
        .padding(.leading, 20)
        .padding(.top, 10)
        .font(.custom("Lato-Regular", size: 15))
        Spacer()
      }
    }
  }
}
