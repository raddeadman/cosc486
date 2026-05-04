import SwiftUI
import PhotosUI
import FirebaseStorage
import UIKit

struct EditProfileView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var pickerItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var isSaving = false
    @State private var errorText: String?

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        profileImageContent
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.secondary.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            Section("Name") {
                TextField("Display name", text: $name)
            }

            Section("Email") {
                Text(authViewModel.currentUser?.email ?? "—")
                    .foregroundStyle(.secondary)
            }

            if let errorText {
                Section {
                    Text(errorText)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Edit profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await save() }
                }
                .disabled(isSaving || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onAppear {
            name = authViewModel.currentUser?.name ?? ""
        }
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    await MainActor.run { imageData = data }
                }
            }
        }
    }

    @ViewBuilder
    private var profileImageContent: some View {
        if let imageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else if let urlString = authViewModel.currentUser?.profileImageUrl,
                  let url = URL(string: urlString),
                  !urlString.isEmpty {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure, .empty:
                    placeholderAvatar
                @unknown default:
                    placeholderAvatar
                }
            }
        } else {
            placeholderAvatar
        }
    }

    private var placeholderAvatar: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.secondary)
            .padding(12)
    }

    private func save() async {
        guard let uid = authViewModel.currentUser?.id else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        await MainActor.run {
            isSaving = true
            errorText = nil
        }

        var uploadedUrl: String?
        if let data = imageData {
            do {
                uploadedUrl = try await uploadProfileImage(data: data, uid: uid)
            } catch {
                await MainActor.run {
                    errorText = error.localizedDescription
                    isSaving = false
                }
                return
            }
        }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            authViewModel.updateProfile(name: trimmed, profileImageUrl: uploadedUrl) { err in
                Task { @MainActor in
                    isSaving = false
                    if let err {
                        errorText = err.localizedDescription
                    } else {
                        dismiss()
                    }
                    continuation.resume()
                }
            }
        }
    }

    private func uploadProfileImage(data: Data, uid: String) async throws -> String {
        let ref = Storage.storage().reference().child("profile_images/\(uid)/avatar.jpg")
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"

        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<String, Error>) in
            ref.putData(data, metadata: meta) { _, error in
                if let error {
                    cont.resume(throwing: error)
                    return
                }
                ref.downloadURL { url, err in
                    if let err {
                        cont.resume(throwing: err)
                    } else if let url {
                        cont.resume(returning: url.absoluteString)
                    } else {
                        cont.resume(throwing: NSError(domain: "Storage", code: 0, userInfo: [NSLocalizedDescriptionKey: "Missing download URL"]))
                    }
                }
            }
        }
    }
}
