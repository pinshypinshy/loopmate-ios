//
//  SessionService.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/06/28.
//

import Foundation

/// アプリ起動時のセッション初期化の結果。
enum SessionStartResult {
    /// プロフィール登録済み。通常の画面を表示する。
    case ready
    /// プロフィール未登録。アカウント登録フローへ誘導する。
    case needsRegistration
}

/// アプリ起動時の初期化（匿名ログイン → プロフィール存在確認 → 登録要否の判定）をまとめて担うサービス。
/// 画面側はこの結果を受け取って表示を切り替えるだけにする。
final class SessionService {

    private let authService: AuthService
    private let userService: UserService

    init(
        authService: AuthService = AuthService(),
        userService: UserService = UserService()
    ) {
        self.authService = authService
        self.userService = userService
    }

    /// 起動時のセッションを確立し、登録フローが必要かどうかを返す。
    func start() async throws -> SessionStartResult {
        let uid = try await authService.signInAnonymouslyIfNeeded()
        let profileExists = try await userService.checkUserProfileExists(uid: uid)
        return profileExists ? .ready : .needsRegistration
    }
}
