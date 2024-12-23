//
//  SwiftUIView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 08/12/24.
//

import SwiftUI
import SwiftData

public struct IpadChatView: View {
  
  @State private var splitViewColumnVisibility: NavigationSplitViewVisibility = .doubleColumn
    var backgroundColor: Color?
    var emptyMessageColor: Color?
    var editButtonColor: Color?
    var subTitle: String?
    var ctx: ModelContext
    var delegate: ConvertVoiceToText
  
    public init(
      backgroundColor: Color? = nil,
      emptyMessageColor: Color? = .white,
      editButtonColor: Color? = .blue,
      subTitle: String? = "General Chat",
      ctx: ModelContext,
      delegate: ConvertVoiceToText
    ) {
      self.backgroundColor = backgroundColor
      self.emptyMessageColor = emptyMessageColor
      self.editButtonColor = editButtonColor
      self.subTitle = subTitle
      self.ctx = ctx
      self.delegate = delegate
    }
  
  public var body: some View {
    NavigationSplitView(columnVisibility: $splitViewColumnVisibility) {
            SomeMainView(
              backgroundColor: backgroundColor,
              emptyMessageColor: emptyMessageColor,
              editButtonColor: editButtonColor,
              subTitle: subTitle,
              ctx: ctx,
              delegate: delegate
            )
    } detail: {
      DetailEmptyView()
    }
    .navigationSplitViewStyle(.balanced)
    
  }
  
}



