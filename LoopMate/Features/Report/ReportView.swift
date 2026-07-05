//
//  ReportView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/07/05.
//

import SwiftUI

/// ユーザーやコンテンツを通報するためのシート。
struct ReportView: View {

    let reportedUid: String
    let contextType: ReportContextType
    var contextId: String? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var selectedReason: ReportReason = .spam
    @State private var isSubmitting = false
    @State private var errorMessage = ""
    @State private var showErrorAlert = false
    @State private var showCompletedAlert = false

    private let reportService = ReportService()

    var body: some View {
        NavigationStack {
            Form {
                Section("理由を選択してください") {
                    Picker("理由", selection: $selectedReason) {
                        ForEach(ReportReason.allCases) { reason in
                            Text(reason.rawValue).tag(reason)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section {
                    Text("通報された内容は運営で確認し、規約に違反していると判断した場合は対応します。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("通報")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        submit()
                    } label: {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("送信")
                        }
                    }
                    .disabled(isSubmitting)
                }
            }
            .alert("エラー", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("通報を送信しました", isPresented: $showCompletedAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text("ご報告ありがとうございます。")
            }
        }
    }

    private func submit() {
        isSubmitting = true

        Task {
            defer { isSubmitting = false }
            do {
                try await reportService.report(
                    reportedUid: reportedUid,
                    contextType: contextType,
                    contextId: contextId,
                    reason: selectedReason
                )
                showCompletedAlert = true
            } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
}

#Preview {
    ReportView(reportedUid: "dummy", contextType: .user)
}
