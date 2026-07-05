//
//  SettingsView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/07/05.
//

import SwiftUI

struct SettingsView: View {

    // MARK: - 規約リンク

    /// 利用規約（Apple 標準の使用許諾契約書 EULA）。
    private let eulaURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    /// プライバシーポリシー。
    private let privacyPolicyURL = URL(string: "https://loopmate-privacy-policy.yuki-hiraishi.com/")!

    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @State private var errorMessage = ""
    @State private var showErrorAlert = false

    private let accountService = AccountService()

    var body: some View {
        ZStack {
            Color(.orange).opacity(Theme.backgroundOpacity).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {

                    // 規約
                    VStack(spacing: 0) {
                        Link(destination: eulaURL) {
                            settingsRow(title: "利用規約", systemImage: "doc.text", trailing: "arrow.up.right")
                        }
                        .buttonStyle(.plain)

                        Divider().padding(.leading, 48)

                        Link(destination: privacyPolicyURL) {
                            settingsRow(title: "プライバシーポリシー", systemImage: "lock.shield", trailing: "arrow.up.right")
                        }
                        .buttonStyle(.plain)
                    }
                    .background(cellBackground)
                    .padding(.horizontal)

                    // 安全
                    NavigationLink {
                        BlockedUsersView()
                    } label: {
                        settingsRow(title: "ブロックしたユーザー", systemImage: "hand.raised", trailing: "chevron.right")
                            .background(cellBackground)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)

                    // アカウント削除
                    Button {
                        showDeleteConfirm = true
                    } label: {
                        HStack(spacing: 8) {
                            Spacer()
                            if isDeleting {
                                ProgressView().tint(.red)
                            }
                            Text("アカウントを削除")
                                .font(.subheadline)
                                .bold()
                                .foregroundStyle(.red)
                            Spacer()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(cellBackground)
                    }
                    .buttonStyle(.plain)
                    .disabled(isDeleting)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    Text("アカウントとすべての関連データ（ルーム・記録・フレンド情報）が削除されます。この操作は取り消せません。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                }
                .padding(.top)
            }
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
        .alert("アカウントを削除しますか？", isPresented: $showDeleteConfirm) {
            Button("キャンセル", role: .cancel) { }
            Button("削除する", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("アカウントとすべての関連データが完全に削除されます。この操作は取り消せません。")
        }
        .alert("エラー", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private var cellBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color(.systemGray6))
    }

    private func settingsRow(title: String, systemImage: String, trailing: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.orange)
                .frame(width: 20)

            Text(title)
                .foregroundStyle(.primary)

            Spacer()

            Image(systemName: trailing)
                .font(.footnote)
                .foregroundStyle(.gray)
        }
        .padding()
        .contentShape(Rectangle())
    }

    private func deleteAccount() {
        isDeleting = true

        Task {
            do {
                try await accountService.deleteAccount()
                // ルート側でセッションを再確立し、登録フローを表示させる。
                NotificationCenter.default.post(name: .accountDeleted, object: nil)
            } catch {
                isDeleting = false
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
