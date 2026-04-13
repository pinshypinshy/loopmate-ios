//
//  SetDisplayNameView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/13.
//

import SwiftUI

struct SetDisplayNameView: View {
    
    @FocusState private var isFocused: Bool
    
    @Binding var username: String
    @Binding var displayName: String
    @Binding var selectedIconName: String
    
    let onCompleted: () -> Void
    
    var body: some View {
        ZStack {
            Color.orange.opacity(Theme.backgroundOpacity).ignoresSafeArea()
            
            VStack(spacing: 40) {
                Text("表示名を設定してください。")
                    .font(.title2)
                    .bold()
                
                TextField("表示名を入力", text: $displayName)
                    .focused($isFocused)
                    .onAppear {
                        isFocused = true
                    }
                    .multilineTextAlignment(.center)
                    .font(.title)
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 40)
        }
        .navigationTitle("アカウント登録")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SetIconView(
                        username: $username,
                        displayName: $displayName,
                        selectedIconName: $selectedIconName,
                        onCompleted: onCompleted
                    )
                } label: {
                    Image(systemName: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .tint(.orange)
                .disabled(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SetDisplayNameView(
            username: .constant(""),
            displayName: .constant(""),
            selectedIconName: .constant("person.crop.circle.fill"),
            onCompleted: {}
        )
    }
}
