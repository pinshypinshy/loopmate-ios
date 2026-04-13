//
//  SetUsernameView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/13.
//

import SwiftUI

struct SetUsernameView: View {
    
    @FocusState private var isFocused: Bool
    
    @Binding var username: String
    @Binding var displayName: String
    @Binding var selectedIconName: String
    
    let onCompleted: () -> Void
    
    @State private var shouldNavigate = false
    @State private var isChecking = false
    @State private var alertMessage = ""
    @State private var showAlert = false
    
    private let userService = UserService()
    
    var body: some View {
        ZStack {
            Color.orange.opacity(Theme.backgroundOpacity).ignoresSafeArea()
            
            VStack(spacing: 40) {
                Text("ユーザーIDを設定してください。")
                    .font(.title2)
                    .bold()
                
                TextField("ユーザーIDを入力", text: $username)
                    .focused($isFocused)
                    .keyboardType(.asciiCapable)
                    .textContentType(.username)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                    .onAppear {
                        isFocused = true
                    }
                    .onChange(of: username) { newValue in
                        let filtered = newValue.lowercased().filter { char in
                            char.isASCII && "abcdefghijklmnopqrstuvwxyz0123456789_".contains(char)
                        }
                        
                        if filtered != newValue {
                            username = filtered
                        }
                    }
                    .multilineTextAlignment(.center)
                    .font(.title)
                    .padding(.horizontal)
                
                if isChecking {
                    ProgressView("確認中...")
                }
                
                Spacer()
            }
            .padding(.top, 40)
        }
        .navigationTitle("アカウント登録")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $shouldNavigate) {
            SetDisplayNameView(
                username: $username,
                displayName: $displayName,
                selectedIconName: $selectedIconName,
                onCompleted: onCompleted
            )
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    checkUsernameAndNavigate()
                } label: {
                    Image(systemName: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .tint(.orange)
                .disabled(username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isChecking)
            }
        }
    }
    
    private func checkUsernameAndNavigate() {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedUsername.isEmpty else { return }
        
        guard isValidUsername(trimmedUsername) else {
            alertMessage = "ユーザーIDは小文字英数字と_のみ使用できます"
            showAlert = true
            return
        }
        
        isChecking = true
        
        userService.isUsernameAvailable(trimmedUsername) { result in
            DispatchQueue.main.async {
                isChecking = false
                
                switch result {
                case .success(let isAvailable):
                    if isAvailable {
                        shouldNavigate = true
                    } else {
                        alertMessage = "このユーザーIDはすでに使われています"
                        showAlert = true
                    }
                    
                case .failure(let error):
                    alertMessage = "ユーザーIDの確認に失敗しました: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
    
    private func isValidUsername(_ username: String) -> Bool {
        let regex = "^[a-z0-9_]+$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: username)
    }
}

#Preview {
    NavigationStack {
        SetUsernameView(
            username: .constant(""),
            displayName: .constant(""),
            selectedIconName: .constant("person.crop.circle.fill"),
            onCompleted: {}
        )
    }
}
