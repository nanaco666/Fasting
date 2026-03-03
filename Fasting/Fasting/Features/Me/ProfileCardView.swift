//
//  ProfileCardView.swift
//  Fasting
//

import SwiftUI
import PhotosUI

struct ProfileCardView: View {
    @AppStorage("user_display_name") private var displayName: String = ""
    @State private var avatarImage: UIImage?
    @State private var photoItem: PhotosPickerItem?
    @State private var showEditName = false

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Avatar
            PhotosPicker(selection: $photoItem, matching: .images) {
                if let image = avatarImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(.tertiary)
                        .frame(width: 80, height: 80)
                }
            }
            .onChange(of: photoItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        avatarImage = uiImage
                        saveAvatar(data)
                    }
                }
            }

            // Name
            Button {
                showEditName = true
                Haptic.light()
            } label: {
                if displayName.isEmpty {
                    Text("Tap to set name".localized)
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                } else {
                    Text(displayName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, Spacing.lg)
        .frame(maxWidth: .infinity)
        .opaqueCard(cornerRadius: CornerRadius.large)
        .onAppear { loadAvatar() }
        .sheet(isPresented: $showEditName) {
            EditNameSheet(name: $displayName)
                .presentationDetents([.medium])
        }
    }

    // MARK: - Avatar persistence

    private static var avatarURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("profile", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("avatar.jpg")
    }

    private func saveAvatar(_ data: Data) {
        try? data.write(to: Self.avatarURL)
    }

    private func loadAvatar() {
        if let data = try? Data(contentsOf: Self.avatarURL),
           let image = UIImage(data: data) {
            avatarImage = image
        }
    }
}
