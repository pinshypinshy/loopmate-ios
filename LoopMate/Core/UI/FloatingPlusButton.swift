//
//  FloatingPlusButton.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/03.
//

import SwiftUI

struct FloatingPlusButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(Circle().fill(Color.orange))
                .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 6)
        }
    }
}

#Preview {
    FloatingPlusButton {
        print("tap")
    }
}
