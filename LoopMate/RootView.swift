//
//  RootView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/13.
//

import SwiftUI
import FirebaseAuth

struct RootView: View {
    @State private var isRegistrationPresented = false
    @State private var hasTriedAnonymousSignIn = false
    
    private let userService = UserService()
    
    var body: some View {
        ContentView()
            .task {
                await setupInitialSession()
            }
            .fullScreenCover(isPresented: $isRegistrationPresented) {
                AccountRegistrationFlowView(
                    onCompleted: {
                        isRegistrationPresented = false
                    }
                )
            }
    }
    
    private func setupInitialSession() async {
        await signInAnonymouslyIfNeeded()
        checkIfUserProfileExists()
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
        
        userService.checkUserProfileExists(uid: uid) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let exists):
                    if exists {
                        print("プロフィールあり")
                        isRegistrationPresented = false
                    } else {
                        print("プロフィールなし")
                        isRegistrationPresented = true
                    }
                    
                case .failure(let error):
                    print("プロフィール確認失敗: \(error)")
                }
            }
        }
    }
}

#Preview {
    RootView()
}
