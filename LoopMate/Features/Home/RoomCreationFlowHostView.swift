//
//  RoomCreationFlowHostView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/12.
//

import SwiftUI

struct RoomCreationFlowHostView: View {
    let onCreateCompleted: (Room) -> Void

    var body: some View {
        RoomCreateView(
            onCreate: { createdRoom in
                onCreateCompleted(createdRoom)
            }
        )
    }
}

#Preview {
    NavigationStack {
        RoomCreationFlowHostView(onCreateCompleted: { _ in })
    }
}
