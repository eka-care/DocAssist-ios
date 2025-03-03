//
//  SwiftUIView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 03/03/25.
//

import SwiftUI

struct SmartNotesView: View {
  
  var success: Bool
  
  var body: some View {
    HStack(spacing: 10) {
      Image(success ? .smartReportSuccess :  .smartReportFailure)
        .resizable()
        .scaledToFit()
        .frame(width: 24, height: 24)
      
      VStack(alignment: .leading, spacing: 2) {
        Text(success ? "Smart notes are ready!" : "Audio analysis failed.")
          .font(.system(size: 16, weight: .regular))
          .foregroundColor(.black)
        
        Text(success ? "Tap to View" : "Tap to try again ")
          .font(.system(size: 14, weight: .medium))
          .foregroundColor(.blue)
          .onTapGesture {
            // Try again
          }
      }
      
      Spacer()
    }
    .padding()
    .frame(width: 250)
    .background(
      LinearGradient(
        gradient: Gradient(
          colors: [ success ?
                    Color(
                      red: 235/255,
                      green: 250/255,
                      blue: 240/255
                    ) : Color(
                      red: 250/255,
                      green: 235/255,
                      blue: 235/255
                    ),
                    Color.white
                  ]
        ),
        startPoint: .top,
        endPoint: .bottom
      )
    )
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
  }
}

