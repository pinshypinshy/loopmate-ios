//
//  ProfileEditView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/14.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileEditView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @Binding var username: String
    @Binding var displayName: String
    @Binding var iconName: String
    
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
    }
    
    private func saveProfile() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("uidが取得できなかった")
            return
        }
        
        let db = Firestore.firestore()
        
        db.collection("users").document(uid).updateData([
            "displayName": displayName,
            "iconName": iconName
        ]) { error in
            if let error = error {
                print("編集保存失敗: \(error)")
            } else {
                print("編集保存成功")
                dismiss()
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileEditView(
            username: .constant("test_user"),
            displayName: .constant("テストユーザー"),
            iconName: .constant("person.crop.circle.fill")
        )
    }
}
