//
//  ProfileEditView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/14.
//

import SwiftUI

struct ProfileEditView: View {

    @Environment(\.dismiss) private var dismiss

    @Binding var displayName: String
    @Binding var iconName: String

    @State private var errorMessage = ""
    @State private var showErrorAlert = false

    private let userService = UserService()

    var body: some View {
        
        ZStack {
            Color.orange.opacity(Theme.backgroundOpacity).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    Image(systemName: iconName)
                        .font(.system(size: 92))
                    NavigationLink {
                        EditIconView(iconName: $iconName)
                    } label: {
                        Text("アイコンを編集")
                    }
                    .tint(.orange)
                    
                    Divider()
                    
                    HStack(spacing: 20) {
                        Text("表示名")
                        
                        TextField("表示名を入力", text: $displayName)
                        
                        Spacer()
                    }
                    
                    Divider()
                }
                .padding()
            }
        }
        .navigationTitle("プロフィールを編集")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    saveProfile()
                } label: {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.white)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .tint(.orange)
            }
        }
        .alert("エラー", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func saveProfile() {
        Task {
            do {
                try await userService.updateProfile(
                    displayName: displayName,
                    iconName: iconName
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileEditView(
            displayName: .constant("テストユーザー"),
            iconName: .constant("person.crop.circle.fill")
        )
    }
}
