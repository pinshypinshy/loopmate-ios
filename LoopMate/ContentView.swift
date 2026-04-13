//
//  ContentView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/03.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("ホーム", systemImage: "house") {
                HomeView()
            }
            Tab("ミッション", systemImage: "list.bullet") {
                MissionView()
            }
            Tab("フレンド", systemImage: "person.2") {
                FriendView()
            }
            Tab("プロフィール", systemImage: "person.circle") {
                ProfileView()
            }
        }
        .tint(.orange)
    }
}

#Preview {
    ContentView()
}
