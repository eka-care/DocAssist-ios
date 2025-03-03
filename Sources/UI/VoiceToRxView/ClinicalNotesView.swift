//
//  SwiftUIView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 03/03/25.
//

import SwiftUI

struct ClinicalNotesView: View {
    var body: some View {
      VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "waveform.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 24))

                VStack(alignment: .leading) {
                    Text("View clinical notes")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    HStack {
                        Text("08 Jan’24")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        Spacer()

                        Text("Saved")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.15))
                            .cornerRadius(8)
                    }
                }
                .padding(.leading, 8)
            }
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            HStack {
                Button(action: {
                    // Play action
                }) {
                    Image(systemName: "play.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 20))
                }

                Text("Recording")
                    .foregroundColor(.gray)
                    .font(.subheadline)

                Spacer()

                Text("01m 04s")
                    .foregroundColor(.gray)
                    .font(.subheadline)

                Button(action: {
                    // Menu action
                }) {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
       
    }
}

struct ClinicalNotesView_Previews: PreviewProvider {
    static var previews: some View {
        ClinicalNotesView()
    }
}
