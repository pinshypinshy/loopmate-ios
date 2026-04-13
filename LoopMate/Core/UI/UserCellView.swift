//
//  UserCellView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/17.
//

import SwiftUI

struct UserCellView: View {
    let user: User
    
    var body: some View {
        HStack {
            Image(systemName: user.iconName)
                .font(.system(size: 44))
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.headline)
                Text(user.username)
                    .font(.subheadline)
            }
            
            Spacer()
        }
    }
}

#Preview {
    UserCellView(user: User.preview)
}
