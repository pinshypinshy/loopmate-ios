//
//  RootView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/13.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RootView: View {
    @State private var isRegistered = false
    @State private var isRegistrationPresented: Bool
    @State private var hasTriedAnonymousSignIn = false
    
    init() {
        _isRegistered = State(initialValue: false)
        _isRegistrationPresented = State(initialValue: false)
    }
    
    var body: some View {
        ContentView()
            .task {
                await signInAnonymouslyIfNeeded()
                checkIfUserProfileExists()
            }
            .fullScreenCover(isPresented: $isRegistrationPresented) {
                AccountRegistrationFlowView(
                    onCompleted: {
                        isRegistered = true
                        isRegistrationPresented = false
                    }
                )
            }
    }
    
    private func signInAnonymouslyIfNeeded() async {
        guard !hasTriedAnonymousSignIn else { return }
        hasTriedAnonymousSignIn = true
        
        if let currentUser = Auth.auth().currentUser {
            print("既にログイン済み uid:", currentUser.uid)
            return
        }
        
        do {
            let result = try await Auth.auth().signInAnonymously()
            print("匿名ログイン成功 uid:", result.user.uid)
        } catch {
            print("匿名ログイン失敗:", error.localizedDescription)
        }
    }
    
    private func checkIfUserProfileExists() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("uidが取れなかったのでプロフィール確認できない")
            return
        }
        
        let db = Firestore.firestore()
        
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("プロフィール確認失敗: \(error)")
                return
            }
            
            if let snapshot = snapshot, snapshot.exists {
                print("プロフィールあり")
                isRegistered = true
                isRegistrationPresented = false
            } else {
                print("プロフィールなし")
                isRegistered = false
                isRegistrationPresented = true
            }
        }
    }
}

#Preview {
    RootView()
}
