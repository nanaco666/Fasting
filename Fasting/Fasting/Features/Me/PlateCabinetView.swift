//
//  PlateCabinetView.swift
//  Fasting
//
//  Skeuomorphic wooden display cabinet for collected plates
//

import SwiftUI

struct PlateCabinetView: View {
    // Static placeholder: first 2 themes collected, rest locked
    private let themes = PlateTheme.allThemes
    private let collectedIds: Set<String> = ["ceramicPlaid", "terracottaWood"]

    var body: some View {
        VStack(spacing: 0) {
            // Cabinet header
            HStack {
                Text("Plate Cabinet".localized)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.brown.opacity(0.8))
                Spacer()
                Text("\(collectedIds.count)/\(themes.count)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.brown.opacity(0.5))
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.sm)

            // Cabinet body
            VStack(spacing: 0) {
                let rows = themes.chunked(into: 3)
                ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                    // Plate row
                    HStack(spacing: Spacing.md) {
                        ForEach(row) { theme in
                            plateSlot(theme: theme, collected: collectedIds.contains(theme.id))
                        }
                        // Fill empty slots in last row
                        if row.count < 3 {
                            ForEach(0..<(3 - row.count), id: \.self) { _ in
                                Color.clear
                                    .aspectRatio(1, contentMode: .fit)
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)

                    // Shelf line (not after last row)
                    if rowIndex < rows.count - 1 {
                        shelfDivider
                    }
                }
            }
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .fill(Color(red: 0.96, green: 0.93, blue: 0.87))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.large)
                            .stroke(Color.brown.opacity(0.25), lineWidth: 2)
                    )
                    .shadow(color: Color.brown.opacity(0.1), radius: 8, y: 4)
            )
            .padding(.horizontal, Spacing.md)

            // Footer
            HStack(spacing: Spacing.xs) {
                Image(systemName: "sparkles")
                    .font(.caption2)
                Text("Unlock more plates by completing plans".localized)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.sm)
        }
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - Plate slot

    @ViewBuilder
    private func plateSlot(theme: PlateTheme, collected: Bool) -> some View {
        ZStack {
            Circle()
                .fill(Color.brown.opacity(0.06))

            if collected, let plateImg = theme.plateImage {
                Image(plateImg)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(6)
                    .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
            } else if collected {
                // Minimal theme — no plate image, show icon
                Image(systemName: "circle.dashed")
                    .font(.title2)
                    .foregroundStyle(theme.progressColor)
            } else {
                // Locked
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(Color.brown.opacity(0.3))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .opacity(collected ? 1 : 0.4)
    }

    // MARK: - Shelf divider

    private var shelfDivider: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.brown.opacity(0.2))
                .frame(height: 2)
            Rectangle()
                .fill(Color.brown.opacity(0.06))
                .frame(height: 4)
        }
        .padding(.horizontal, Spacing.sm)
    }
}

// MARK: - Array chunking helper

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
