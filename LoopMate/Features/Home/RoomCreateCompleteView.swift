//
//  RoomCreateCompleteView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/11.
//

import SwiftUI
import UIKit

struct RoomCreateCompleteView: View {
    
    let room: Room
    let onClose: () -> Void
    
    @State private var isCopied = false
    
    var body: some View {
        ZStack {
            Color.orange.ignoresSafeArea()
            
            VStack(spacing: 16) {
                
                Spacer()
                
                Text("ルームを作成しました")
                    .font(.title2)
                    .bold()
                    .foregroundStyle(.white)
                    .padding(.bottom, 80)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.6))
                                .frame(width: 28, height: 28)
                            
                            Image(systemName: room.iconName)
                                .font(.system(size: 14))
                                .foregroundStyle(.orange)
                                .frame(width: 28, height: 28)
                                .background(Color.orange.opacity(0.12))
                                .clipShape(Circle())
                        }
                        
                        Text(room.name)
                            .font(.headline)
                            .bold()
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    HStack() {
                        Text("ルームコード：\(room.code)")
                            .font(.headline)
                            .bold()
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        Button {
                            UIPasteboard.general.string = room.code
                            
                            isCopied = true
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                isCopied = false
                            }
                        } label: {
                            Image(systemName: isCopied ? "checkmark" : "square.on.square")
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Color.gray.opacity(0.25))
                .cornerRadius(16)
                .padding(.bottom, 60)
                
                Spacer()
                
                /*
                Button {
                    
                } label: {
                    Text("フレンドを招待")
                        .font(.title3)
                        .bold()
                        .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                 */
                
                Button {
                    onClose()
                } label: {
                    Text("閉じる")
                        .font(.headline)
                        .bold()
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white, lineWidth: 2)
                )
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    RoomCreateCompleteView(room: .preview, onClose: {})
}
