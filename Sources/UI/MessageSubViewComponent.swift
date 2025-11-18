//
//  MessageSubViewComponent.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 17/06/25.
//

import SwiftUI

struct MessageSubViewComponent: View {
  let title: String
  let date: String
  let subTitle: String?
  let foregroundColor: Bool
  let allChat: Bool
  
  var body: some View {
    if let isCalledFromPatientApp = SetUIComponents.shared.isPatientApp, isCalledFromPatientApp {
      VStack(spacing: 5) {
        Spacer()
        HStack {
          Text(title)
            .font(.custom("Lato-Regular", size: 16))
            .foregroundColor(UIDevice.current.userInterfaceIdiom == .pad ? (foregroundColor ? .white : .primary) : .primary)
            .multilineTextAlignment(.leading)
            .lineLimit(2)
          Spacer()
          Text(date)
            .font(.caption)
            .foregroundStyle(UIDevice.current.userInterfaceIdiom == .pad ? (foregroundColor ? .white : .gray) : Color.gray)
          Image(systemName: "chevron.right")
            .resizable()
            .scaledToFit()
            .frame(width: 6)
            .foregroundStyle(UIDevice.current.userInterfaceIdiom == .pad ? (foregroundColor ? .white : .gray) : Color.gray)
        }
        Spacer()
        Divider()
      }
      
    }
    else {
      VStack {
        HStack {
          nameInitialsView(initials: getInitials(name: title ?? "GeneralChat") ?? "GC")
          VStack(spacing: 6) {
            HStack {
              Text(title)
                .font(.custom("Lato-Regular", size: 16))
                .foregroundColor(UIDevice.current.userInterfaceIdiom == .pad ? (foregroundColor ? .white : .primary) : .primary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
              Spacer()
            }
            HStack {
              Text(subTitle ?? "General Chat")
                .font(.custom("Lato-Regular", size: 14))
                .fontWeight(.regular)
                .foregroundStyle(UIDevice.current.userInterfaceIdiom == .phone ? Color.gray : (foregroundColor ? .white : .gray))
                .lineLimit(1)
              Spacer()
              Text(date)
                .font(.caption)
                .foregroundStyle(UIDevice.current.userInterfaceIdiom == .phone ? Color.gray : (foregroundColor ? .white : .gray))
              Image(systemName: "chevron.right")
                .resizable()
                .scaledToFit()
                .frame(width: 6)
                .foregroundStyle(UIDevice.current.userInterfaceIdiom == .phone ? Color.gray : (foregroundColor ? .white : .gray))
            }
            Divider()
          }
        }
      }
      .padding(UIDevice.current.userInterfaceIdiom == .pad ? 3 : 0)
    }
  }
}
