//
//  RootView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/13.
//

import SwiftUI

struct RootView: View {
    @State private var isRegistrationPresented = false // アカウント登録フローを全画面表示するかのフラグ

    private let sessionService = SessionService()

    var body: some View {
        ContentView()
            .task {
                await startSession()
            }
            .fullScreenCover(isPresented: $isRegistrationPresented) {
                AccountRegistrationFlowView(
                    onCompleted: {
                        isRegistrationPresented = false
                    }
                )
            }
    }

    private func startSession() async {
        do {
            let result = try await sessionService.start()
            isRegistrationPresented = (result == .needsRegistration)
        } catch {
            print("セッション初期化失敗: \(error.localizedDescription)")
        }
    }
}

#Preview {
    RootView()
}
