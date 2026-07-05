//
//  ReportService.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/07/05.
//

import Foundation
import FirebaseFirestore

/// 通報の理由。
enum ReportReason: String, CaseIterable, Identifiable {
    case spam = "スパム・宣伝"
    case harassment = "迷惑行為・嫌がらせ"
    case inappropriate = "不適切なコンテンツ"
    case other = "その他"

    var id: String { rawValue }
}

/// 通報対象の種別。
enum ReportContextType: String {
    /// ユーザーそのものの通報。
    case user
    /// ミッション記録（コメント等）の通報。
    case missionRecord
}

/// ユーザーやコンテンツの通報を受け付けるサービス。
/// 通報内容は `reports` コレクションに保存する。
final class ReportService {

    private let db = Firestore.firestore()
    private let authService = AuthService()

    /// 通報を送信する。
    /// - Parameters:
    ///   - reportedUid: 通報対象ユーザーの UID
    ///   - contextType: 通報対象の種別
    ///   - contextId: 対象コンテンツの識別子（ユーザー通報など不要な場合は nil）
    ///   - reason: 通報理由
    func report(
        reportedUid: String,
        contextType: ReportContextType,
        contextId: String? = nil,
        reason: ReportReason
    ) async throws {
        let reporterUid = try authService.requireUid()

        let data: [String: Any] = [
            "reporterUid": reporterUid,
            "reportedUid": reportedUid,
            "contextType": contextType.rawValue,
            "contextId": contextId as Any,
            "reason": reason.rawValue,
            "createdAt": Timestamp(date: Date())
        ]

        try await db.collection("reports").addDocument(data: data)
    }
}
