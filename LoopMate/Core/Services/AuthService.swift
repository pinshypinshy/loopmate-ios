//
//  AuthService.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/06/28.
//

import Foundation
import FirebaseAuth

/// 認証まわりの責務を担うサービス。
/// 画面側は Auth を直接触らず、このサービス経由でログイン状態を扱う。
final class AuthService {

    /// 現在ログイン中のユーザーの uid。未ログインなら nil。
    var currentUid: String? {
        Auth.auth().currentUser?.uid
    }

    /// 未ログインのときだけ匿名ログインし、確定した uid を返す。
    /// すでにログイン済みなら何もせず既存の uid を返す（Firebase がセッションを永続化するため再起動後も維持される）。
    func signInAnonymouslyIfNeeded() async throws -> String {
        if let currentUser = Auth.auth().currentUser {
            return currentUser.uid
        }

        let result = try await Auth.auth().signInAnonymously()
        return result.user.uid
    }
}
