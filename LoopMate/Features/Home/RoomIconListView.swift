//
//  RoomIconListView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/18.
//

import SwiftUI

struct RoomIconListView: View {
    
    @Binding var selectedIconName: String
    @Environment(\.dismiss) private var dismiss
    
    private let iconSections: [RoomIconSection] = [
        RoomIconSection(
            title: "習慣・目標",
            icons: [
                "checkmark.circle",
                "checkmark.seal",
                "target",
                "flag",
                "star",
                "trophy",
                "medal",
                "rosette"
            ]
        ),
        RoomIconSection(
            title: "勉強",
            icons: [
                "book",
                "books.vertical",
                "pencil",
                "pencil.and.ruler",
                "graduationcap",
                "doc.text",
                "folder",
                "brain"
            ]
        ),
        RoomIconSection(
            title: "仕事・作業",
            icons: [
                "briefcase",
                "desktopcomputer",
                "laptopcomputer",
                "keyboard",
                "calendar",
                "clock",
                "chart.bar",
                "list.bullet"
            ]
        ),
        RoomIconSection(
            title: "運動・健康",
            icons: [
                "figure.run",
                "dumbbell",
                "heart",
                "heart.circle",
                "bolt.heart",
                "cross.case",
                "bed.double",
                "lungs"
            ]
        ),
        RoomIconSection(
            title: "生活",
            icons: [
                "house",
                "leaf",
                "drop",
                "fork.knife",
                "cup.and.saucer",
                "cart",
                "shower",
                "washer"
            ]
        ),
        RoomIconSection(
            title: "趣味",
            icons: [
                "music.note",
                "headphones",
                "gamecontroller",
                "camera",
                "film",
                "paintpalette",
                "guitars",
                "tv"
            ]
        ),
        RoomIconSection(
            title: "お金・管理",
            icons: [
                "yensign.circle",
                "creditcard",
                "wallet.pass",
                "banknote",
                "chart.pie",
                "tray.full",
                "archivebox",
                "checklist"
            ]
        ),
        RoomIconSection(
            title: "その他",
            icons: [
                "sun.max",
                "moon",
                "cloud",
                "flame",
                "sparkles",
                "gift",
                "pawprint",
                "person.2"
            ]
        )
    ]
    
    private let columns = [
        GridItem(.adaptive(minimum: 72, maximum: 88), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(iconSections) { section in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(section.title)
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(section.icons, id: \.self) { iconName in
                                Button {
                                    selectedIconName = iconName
                                    dismiss()
                                } label: {
                                    VStack(spacing: 10) {
                                        Image(systemName: iconName)
                                            .font(.system(size: 24, weight: .medium))
                                            .frame(width: 52, height: 52)
                                            .background(
                                                selectedIconName == iconName
                                                ? Color.orange.opacity(0.18)
                                                : Color(.systemGray6)
                                            )
                                            .clipShape(Circle())
                                            .foregroundStyle(
                                                selectedIconName == iconName
                                                ? .orange
                                                : .primary
                                            )
                                        
                                        if selectedIconName == iconName {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 14))
                                                .foregroundStyle(.orange)
                                        } else {
                                            Color.clear
                                                .frame(width: 14, height: 14)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color.orange.opacity(Theme.backgroundOpacity))
        .navigationTitle("アイコン")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct RoomIconSection: Identifiable {
    let id = UUID()
    let title: String
    let icons: [String]
}

#Preview {
    NavigationStack {
        RoomIconListView(selectedIconName: .constant("checkmark.circle"))
    }
}
