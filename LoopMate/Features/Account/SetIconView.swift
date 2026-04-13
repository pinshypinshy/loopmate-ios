//
//  SetIconView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/13.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SetIconView: View {
    
    @Binding var username: String
    @Binding var displayName: String
    @Binding var selectedIconName: String
    
    let onCompleted: () -> Void
    
    let iconCandidates = [
        "person.crop.circle.fill",
        "person.circle.fill",
        "face.smiling.fill",
        "star.circle.fill",
        "heart.circle.fill",
        "moon.circle.fill"
    ]
    
    var body: some View {
        ZStack {
            Color.orange.opacity(Theme.backgroundOpacity).ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("アイコンを設定")
                    .font(.title2)
                    .bold()
                
                Image(systemName: selectedIconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .padding()
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                    ForEach(iconCandidates, id: \.self) { icon in
                        Button {
                            selectedIconName = icon
                        } label: {
                            Image(systemName: icon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    selectedIconName == icon
                                    ? Color.orange.opacity(0.6)
                                    : Color.gray.opacity(0.1)
                                )
                                .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 40)
        }
        .navigationTitle("アカウント登録")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    registerAccount()
                } label: {
                    Image(systemName: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .tint(.orange)
            }
        }
    }
    
    func registerAccount() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("uidが取得できなかった")
            return
        }
        
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let usernameKey = trimmedUsername.lowercased()
        
        guard isValidUsername(trimmedUsername) else {
            print("不正なユーザーID")
            return
        }
        
        let db = Firestore.firestore()
        
        db.collection("users")
            .whereField("usernameKey", isEqualTo: usernameKey)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("確認失敗: \(error)")
                    return
                }
                
                let documents = snapshot?.documents ?? []
                let existsOtherUser = documents.contains { $0.documentID != uid }
                
                if existsOtherUser {
                    print("このユーザーIDはすでに使われています")
                    return
                }
                
                let data: [String: Any] = [
                    "username": trimmedUsername,
                    "usernameKey": usernameKey,
                    "displayName": trimmedDisplayName,
                    "iconName": selectedIconName
                ]
                
                db.collection("users").document(uid).setData(data) { error in
                    if let error = error {
                        print("保存失敗: \(error)")
                    } else {
                        print("保存成功")
                        onCompleted()
                    }
                }
            }
    }

    private func isValidUsername(_ username: String) -> Bool {
        let regex = "^[a-z0-9_]+$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: username)
    }
}

#Preview {
    NavigationStack {
        SetIconView(
            username: .constant(""),
            displayName: .constant(""),
            selectedIconName: .constant("person.crop.circle.fill"),
            onCompleted: {}
        )
    }
}
