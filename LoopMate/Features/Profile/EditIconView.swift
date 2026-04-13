//
//  EditIconView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/14.
//

import SwiftUI

struct EditIconView: View {
    
    @Binding var iconName: String
    
    let iconCandidates = [
        "person.crop.circle.fill",
        "person.circle.fill",
        "face.smiling.fill",
        "star.circle.fill",
        "heart.circle.fill",
        "moon.circle.fill"
    ]
    
    var body: some View {
        ZStack {
            Color.orange.opacity(Theme.backgroundOpacity).ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("アイコンを選択")
                    .font(.title2)
                    .bold()
                
                Image(systemName: iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .padding()
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                    ForEach(iconCandidates, id: \.self) { icon in
                        Button {
                            iconName = icon
                        } label: {
                            Image(systemName: icon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    iconName == icon
                                    ? Color.orange.opacity(0.6)
                                    : Color.gray.opacity(0.1)
                                )
                                .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 40)
        }
        .navigationTitle("アイコンを編集")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        EditIconView(iconName: .constant("person.crop.circle.fill"))
    }
}
