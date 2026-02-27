//
//  PlateTheme.swift
//  Fasting
//
//  主题系统 — 桌布背景 + 餐盘容器
//  支持：图片桌布、纯色桌布、用户自定义图片
//

import SwiftUI

// MARK: - Background Type

enum ThemeBackground: Equatable {
    /// Solid color with optional gradient (original style)
    case solid(light: Color, dark: Color)
    /// Image with auto-detected edge color for gradient blend
    case image(assetName: String)
    /// User-uploaded image (stored in documents)
    case custom(fileName: String)
    
    static func == (lhs: ThemeBackground, rhs: ThemeBackground) -> Bool {
        switch (lhs, rhs) {
        case (.solid(let l1, let d1), .solid(let l2, let d2)):
            return l1 == l2 && d1 == d2
        case (.image(let a), .image(let b)):
            return a == b
        case (.custom(let a), .custom(let b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: - Theme Definition

struct PlateTheme: Identifiable, Equatable {
    let id: String
    let name: String
    let localizedName: String
    
    // Background (tablecloth)
    let background: ThemeBackground
    let blendColor: Color             // Color the image fades into (match system bg)
    let fadeStart: CGFloat            // 0-1, where fade begins
    let fadeEnd: CGFloat              // 0-1, where fully transparent
    
    // Plate appearance
    let plateImage: String?           // Asset name for plate texture
    let plateScale: CGFloat           // How much bigger plate is vs dial (1.0 = same, 1.3 = 30% bigger)
    
    // Colors
    let progressColor: Color
    let progressTrackColor: Color
    
    let isPremium: Bool
    
    // Convenience: does this theme have a visual plate?
    var hasPlate: Bool { plateImage != nil }
}

// MARK: - Built-in Themes

extension PlateTheme {
    
    /// Original — pure gradient, no images
    static let minimal = PlateTheme(
        id: "minimal",
        name: "Minimal",
        localizedName: "theme_minimal".localized,
        background: .solid(
            light: Color(red: 0.98, green: 0.98, blue: 1.0),
            dark: Color(red: 0.11, green: 0.11, blue: 0.12)
        ),
        blendColor: Color.clear,
        fadeStart: 0, fadeEnd: 0,
        plateImage: nil,
        plateScale: 1.0,
        progressColor: Color.fastingGreen,
        progressTrackColor: Color.gray.opacity(0.1),
        isPremium: false
    )
    
    /// Classic — linen tablecloth + ceramic plate
    static let classic = PlateTheme(
        id: "classic",
        name: "Classic",
        localizedName: "theme_classic".localized,
        background: .image(assetName: "tablecloth_linen"),
        blendColor: Color(red: 0.96, green: 0.94, blue: 0.90),
        fadeStart: 0.3, fadeEnd: 0.65,
        plateImage: "plate_castiron",
        plateScale: 1.25,
        progressColor: Color.fastingGreen,
        progressTrackColor: Color.gray.opacity(0.1),
        isPremium: false
    )
    
    /// Dark wood + cast iron
    static let ironwood = PlateTheme(
        id: "ironwood",
        name: "Ironwood",
        localizedName: "theme_ironwood".localized,
        background: .image(assetName: "tablecloth_darkwood"),
        blendColor: Color(red: 0.12, green: 0.10, blue: 0.08),
        fadeStart: 0.25, fadeEnd: 0.6,
        plateImage: "plate_castiron",
        plateScale: 1.25,
        progressColor: Color.fastingOrange,
        progressTrackColor: Color.white.opacity(0.08),
        isPremium: false
    )
    
    /// Marble + blue enamel
    static let marble = PlateTheme(
        id: "marble",
        name: "Marble",
        localizedName: "theme_marble".localized,
        background: .image(assetName: "tablecloth_marble"),
        blendColor: Color(red: 0.92, green: 0.92, blue: 0.93),
        fadeStart: 0.3, fadeEnd: 0.65,
        plateImage: nil,
        plateScale: 1.0,
        progressColor: Color.fastingTeal,
        progressTrackColor: Color.fastingTeal.opacity(0.1),
        isPremium: false
    )
    
    /// Japanese washi paper + wooden plate
    static let washi = PlateTheme(
        id: "washi",
        name: "Washi",
        localizedName: "theme_washi".localized,
        background: .image(assetName: "tablecloth_washi"),
        blendColor: Color(red: 0.95, green: 0.93, blue: 0.88),
        fadeStart: 0.3, fadeEnd: 0.65,
        plateImage: "plate_wood",
        plateScale: 1.25,
        progressColor: Color.fastingGreen,
        progressTrackColor: Color.brown.opacity(0.1),
        isPremium: true
    )
    
    static let allThemes: [PlateTheme] = [.minimal, .classic, .ironwood, .marble, .washi]
    
    static func theme(for id: String) -> PlateTheme {
        allThemes.first { $0.id == id } ?? .classic
    }
}

// MARK: - Theme Manager

@Observable
final class ThemeManager {
    static let shared = ThemeManager()
    
    var currentTheme: PlateTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.id, forKey: "selectedThemeId")
        }
    }
    
    private init() {
        let savedId = UserDefaults.standard.string(forKey: "selectedThemeId") ?? "classic"
        self.currentTheme = PlateTheme.theme(for: savedId)
    }
    
    /// Directory for user-uploaded tablecloth images
    static var customImageDirectory: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("themes", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}

// MARK: - Tablecloth Background View

struct TableclothBackground: View {
    let theme: PlateTheme
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        GeometryReader { geo in
            switch theme.background {
            case .solid(let light, let dark):
                // Original gradient style
                LinearGradient(
                    colors: [
                        colorScheme == .dark ? dark : light,
                        colorScheme == .dark ? dark.opacity(0.8) : light.opacity(0.8)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
            case .image(let assetName):
                imageBackground(Image(assetName), size: geo.size)
                
            case .custom(let fileName):
                let url = ThemeManager.customImageDirectory.appendingPathComponent(fileName)
                if let uiImage = UIImage(contentsOfFile: url.path) {
                    imageBackground(Image(uiImage: uiImage), size: geo.size)
                } else {
                    Color(.systemBackground)
                }
            }
        }
        .ignoresSafeArea()
    }
    
    private func imageBackground(_ image: Image, size: CGSize) -> some View {
        ZStack {
            // Base: blend color fills entire background
            (colorScheme == .dark ? Color(.systemBackground) : theme.blendColor)
            
            // Image: top-aligned, fades out
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .clipped()
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .white, location: 0),
                            .init(color: .white, location: theme.fadeStart),
                            .init(color: .clear, location: theme.fadeEnd),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }
}
