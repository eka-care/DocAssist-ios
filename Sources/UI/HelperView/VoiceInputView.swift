//
//  VoiceInputView.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 08/07/25.
//

import SwiftUI

struct VoiceInputView: View {
    var viewModel: ChatViewModel
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Button {
                viewModel.dontRecord()
            } label: {
                Image(systemName: "xmark")
                    .frame(width: 24, height: 24)
                    .padding(6)
            }
            .frame(width: 36, height: 36)
            .background(Color.white)
            .cornerRadius(18)
            
            if viewModel.isRecording {
                AudioWaveformView()
                    .frame(height: 36)
                    .layoutPriority(1)
            } else {
                Spacer()
                    .frame(height: 36)
            }
            
            TimerView(isTimerRunning: !viewModel.voiceProcessing)
                .frame(width: 60)
            
            if viewModel.voiceProcessing {
                ProgressView()
                    .frame(width: 36, height: 36)
            }
            
            if !viewModel.voiceProcessing {
                Button {
                    viewModel.stopRecording()
                } label: {
                    Image(systemName: "checkmark")
                        .frame(width: 24, height: 24)
                        .padding(6)
                }
                .frame(width: 36, height: 36)
                .background(Color.white)
                .cornerRadius(18)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .padding(.horizontal, 8)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .inset(by: -0.5)
                .stroke(Color(red: 0.83, green: 0.87, blue: 1), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
