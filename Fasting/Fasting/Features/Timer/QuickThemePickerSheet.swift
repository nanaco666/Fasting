//
//  QuickThemePickerSheet.swift
//  Fasting
//
//  Compact theme picker — presented from toolbar.
//

import SwiftUI

struct QuickThemePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    private let themes = PlateTheme.allThemes
    
    var body: some View {
        NavigationStack {
        VStack(spacing: 16) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(themes) { theme in
                        let isSelected = ThemeManager.shared.currentTheme.id == theme.id
                        
                        Button {
                            withAnimation(.smoothSpring) {
                                ThemeManager.shared.currentTheme = theme
                            }
                            Haptic.light()
                            dismiss()
                        } label: {
                            VStack(spacing: 8) {
                                themePreview(theme)
                                    .frame(width: 72, height: 72)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(isSelected ? theme.progressColor : .clear, lineWidth: 2.5)
                                    }
                                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                                
                                Text(theme.localizedName)
                                    .font(.caption2.weight(isSelected ? .bold : .regular))
                                    .foregroundStyle(isSelected ? theme.progressColor : .secondary)
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .padding(.vertical, 20)
        .navigationTitle("theme_picker_title".localized)
        .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    @ViewBuilder
    private func themePreview(_ theme: PlateTheme) -> some View {
        switch theme.background {
        case .image(let assetName):
            Image(assetName)
                .resizable()
                .aspectRatio(contentMode: .fill)
        case .solid(let light, _):
            light
        case .custom:
            Color.gray.opacity(0.2)
        }
    }
}

#Preview {
    QuickThemePickerSheet()
        .presentationDetents([.height(280)])
}
