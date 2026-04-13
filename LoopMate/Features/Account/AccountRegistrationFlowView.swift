//
//  AccountRegistrationFlowView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/13.
//

import SwiftUI

struct AccountRegistrationFlowView: View {
    
    let onCompleted: () -> Void
    
    @State private var username: String = ""
    @State private var displayName: String = ""
    @State private var selectedIconName: String = "person.crop.circle.fill"
    
    var body: some View {
        NavigationStack {
            SetUsernameView(
                username: $username,
                displayName: $displayName,
                selectedIconName: $selectedIconName,
                onCompleted: onCompleted
            )
        }
    }
}

#Preview {
    AccountRegistrationFlowView(onCompleted: {})
}
