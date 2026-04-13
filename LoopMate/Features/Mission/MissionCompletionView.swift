//
//  MissionCompletionView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/12.
//

import SwiftUI
import PhotosUI
import UIKit

struct MissionCompletionView: View {
    
    let room: Room
    
    @Environment(\.dismiss) private var dismiss
    
    @State var value: String = ""
    @State var comment: String = ""
    
    @State private var showPhotoSourceDialog = false
    @State private var showCameraPicker = false
    @State private var showPhotoLibraryPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    
    @State private var errorMessage = ""
    @State private var showErrorAlert = false
    @State private var isSaving = false
    
    private let missionService = MissionService()
    
    var body: some View {
        
        ZStack {
            Color.orange.opacity(Theme.backgroundOpacity).ignoresSafeArea()
            ScrollView {
                VStack {
                    if room.isPhotoRequired {
                        Button {
                            showPhotoSourceDialog = true
                        } label: {
                            VStack {
                                HStack {
                                    Text("写真を追加")
                                        .foregroundStyle(.orange)
                                    
                                    Spacer()
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                
                                if let selectedImage {
                                    Divider()
                                    
                                    Image(uiImage: selectedImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity)
                                        .clipped()
                                        .cornerRadius(8)
                                        .padding()
                                }
                            }
                            .background(
                                inputBackground(cornerRadius: 12)
                            )
                            
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        .padding(.top)
                        .confirmationDialog(
                            "写真を追加",
                            isPresented: $showPhotoSourceDialog,
                            titleVisibility: .visible
                        ) {
                            Button("撮影") {
                                showCameraPicker = true
                            }
                            
                            Button("アルバム") {
                                showPhotoLibraryPicker = true
                            }
                            
                            Button("キャンセル", role: .cancel) { }
                        }
                    }
                    
                    if room.isNumberRequired {
                        TextField("数値を入力", text: $value)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(
                                inputBackground(cornerRadius: 12)
                            )
                            .padding(.horizontal)
                            .padding(.top)
                    }
                    
                    VStack {
                        ZStack(alignment: .topLeading) {
                            inputBackground(cornerRadius: 16)
                                .frame(height: 140)
                            
                            if comment.isEmpty {
                                Text("コメントを入力")
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 14)
                                    .padding(.leading, 14)
                            }
                            
                            TextEditor(text: $comment)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 8)
                                .frame(height: 140)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle(room.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    register()
                } label: {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("登録")
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(isSaving)
            }
        }
        .photosPicker(
            isPresented: $showPhotoLibraryPicker,
            selection: $selectedPhotoItem,
            matching: .images
        )
        .task(id: selectedPhotoItem) {
            guard let selectedPhotoItem else { return }
            
            if let data = try? await selectedPhotoItem.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                selectedImage = uiImage
            }
        }
        .sheet(isPresented: $showCameraPicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
        }
        .alert("エラー", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        
    }
    
    private func inputBackground(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color(uiColor: .secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color(uiColor: .separator), lineWidth: 0.5)
            )
    }
    
    private func register() {
        
        let valueDouble = Double(value)
        
        if room.isNumberRequired && valueDouble == nil {
            errorMessage = "数値を入力してください"
            showErrorAlert = true
            return
        }
        
        if room.isPhotoRequired && selectedImage == nil {
            errorMessage = "写真を追加してください"
            showErrorAlert = true
            return
        }
        
        isSaving = true
        
        if let selectedImage {
            missionService.uploadMissionPhoto(image: selectedImage, roomId: room.id) { result in
                switch result {
                case .success(let photoURL):
                    saveMissionRecord(value: valueDouble, photoURL: photoURL)
                    
                case .failure(let error):
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        } else {
            saveMissionRecord(value: valueDouble, photoURL: nil)
        }
    }
    
    private func saveMissionRecord(value: Double?, photoURL: String?) {
        missionService.saveRecord(
            room: room,
            value: value,
            comment: comment,
            photoURL: photoURL
        ) { result in
            isSaving = false
            
            switch result {
            case .success:
                dismiss()
                
            case .failure(let error):
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    let sourceType: UIImagePickerController.SourceType
    
    func makeCoordinator() -> Coordinator {
        Coordinator(selectedImage: $selectedImage)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
    }
    
    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        @Binding var selectedImage: UIImage?
        
        init(selectedImage: Binding<UIImage?>) {
            _selectedImage = selectedImage
        }
        
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                selectedImage = image
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    NavigationStack {
        MissionCompletionView(room: Room.preview)
    }
}
