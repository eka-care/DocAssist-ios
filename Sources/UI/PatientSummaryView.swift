//
//  SwiftUIView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 17/01/25.
//

import SwiftUI
import SwiftData

struct PatientSummaryView: View {
  @State var patientName: String
  
  init(patientName: String) {
    self.patientName = patientName
  }
    var body: some View {
      VStack {
        VStack(alignment: .center, spacing: 11.5) {
          Text("AB")
            .font(.custom("Lato-Bold", size: 34))
            .foregroundColor(Color(red: 0.13, green: 0.36, blue: 1))
        }
        .padding(0)
        .frame(width: 80, height: 80, alignment: .center)
        .background(.white)
        .cornerRadius(310.5)
        
        Text(patientName)
          .font(.custom("Lato-Bold", size: 28))
          .multilineTextAlignment(.center)
          .foregroundColor(.white)
          .frame(maxWidth: .infinity, alignment: .center)
        
        Text("Patient Detail")
        
        HStack(alignment: .center, spacing: 8) {
          BlurButton(image: UIImage(resource: .chats), title: "New chat")
          BlurButton(image: UIImage(resource: .vToRx), title: "New document")
        }
        .padding(0)
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding(.horizontal, 16)
      .padding(.top, 0)
      .padding(.bottom, 20)
      .frame(maxWidth: .infinity, alignment: .bottom)
      .background(
        LinearGradient(
          stops: [
            Gradient.Stop(color: Color(red: 0.2, green: 0.28, blue: 0.54), location: 0.00),
            Gradient.Stop(color: Color(red: 0.9, green: 0.68, blue: 1), location: 1.00),
          ],
          startPoint: UnitPoint(x: 0.5, y: 1),
          endPoint: UnitPoint(x: 0.5, y: 0)
        )
      )
      .onAppear {
        
      }
    }
}

struct BlurButton: View {
  
  var image: UIImage
  var title: String
  
  var body: some View {
    
    Button {
      
    } label: {
      VStack(alignment: .center, spacing: 0) {
        HStack(alignment: .center, spacing: 10) {
          Image(uiImage: image)
        }
        .padding(8)
        
        Text(title)
          .font(.custom("Lato-Bold", size: 12))
          .foregroundColor(.white)
      }
      .padding(.horizontal, 0)
      .padding(.top, 0)
      .padding(.bottom, 8)
      .frame(maxWidth: .infinity, alignment: .center)
      .background(.white.opacity(0.12))
      .cornerRadius(8)
    }
  }
}

struct ChatListView: View {
  var body: some View {
    VStack(spacing: 16) {
      ScrollView {
      Button {
        
      } label : {
        
        VStack(alignment: .leading, spacing: 0) {
          HStack(alignment: .center, spacing: 4) {
            
            VStack(alignment: .center, spacing: 10) {
              Image(.fileWaveForm)
            }
            .padding(6)
            .background(Color(red: 0.46, green: 0.46, blue: 0.46))
            .cornerRadius(6)
            
            HStack(alignment: .center, spacing: 8) {
              Text("Clinical notes")
                .font(Font.custom("Lato-Regular", size: 16))
                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
            }
            .padding(0)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(alignment: .center, spacing: 0) {
              Text("32")
                .font(Font.custom("Lato-Regular", size: 16))
                .multilineTextAlignment(.trailing)
                .foregroundColor(Color(red: 0.64, green: 0.64, blue: 0.64))
              HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .center, spacing: 10) {
                  Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
                }
                .padding(4)
                .frame(width: 16, height: 32, alignment: .center)
              }
              .padding(.leading, 0)
              .padding(.trailing, 16)
              .padding(.vertical, 0)
              
            }
            .padding(.leading, 28)
            .padding(.trailing, 0)
            .padding(.vertical, 4)
          }
          .padding(.leading, 16)
          .padding(.trailing, 0)
          .padding(.vertical, 0)
          .frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44, alignment: .leading)
        }
        .padding(0)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(.white)
        .cornerRadius(8)
        .padding(.top, 10)
      }
    
      Text("5 chats found")
        .foregroundColor(.gray)
        .font(.custom("Lato-Regular", size: 14))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
      }
      .scrollIndicators(.hidden)
    }
    .padding(.leading, 16)
    .padding(.trailing, 16)
    .padding(.top, 8)
    .padding(.bottom, 8)
    .background(Color.gray.opacity(0.1))
  }
}

struct ChatRow: View {
    let title: String
    let subtitle: String
    var draftCount: String? = nil
    let time: String
    let vm: ChatViewModel
    let sessionId: String
    let patientName: String
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
        NavigationLink {
            ActiveChatView(
              session: sessionId,
                viewModel: vm,
                backgroundColor: .white,
                patientName: patientName,
                calledFromPatientContext: false,
                title: title
            ).modelContext(modelContext)
            
        } label: {
            HStack(spacing: 12) {
                Image(.chat)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(Font.custom("Lato-Regular", size: 16))
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    HStack {
                        Text(subtitle)
                            .font(Font.custom("Lato-Regular", size: 14))
                            .foregroundColor(Color(red: 0.64, green: 0.64, blue: 0.64))
                        
//                        Text(draftCount ?? "2 draft")
//                            .font(Font.custom("Lato-Regular", size: 14))
//                            .foregroundColor(Color(red: 0.56, green: 0.41, blue: 0.03))
                        
                        Spacer()
                        
                        Text(time)
                            .font(Font.custom("Lato-Regular", size: 13))
                            .foregroundColor(Color(red: 0.64, green: 0.64, blue: 0.64))
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.system(size: 12))
                            .frame(width: 16, height: 16)
                    }
                }
            }
            .padding(.leading, 15)
            .padding(.trailing, 15)
            .padding(.top, 5)
            .padding(.bottom, 5)

        }
    }
}


struct CompleteView: View {
  var patientName: String
  
  init(patientName: String) {
    self.patientName = patientName
  }
  
  var body: some View {
    VStack(spacing: 0) {
      PatientSummaryView(patientName: patientName)
      ChatListView()
    }
  }
}

struct DetailView: View {
  var session: String
  
  init(session: String) {
    self.session = session
  }
  
  var body: some View {
    Text("Hello world")
    Text(session)
  }
}
