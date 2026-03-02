//
//  PlateTheme.swift
//  Fasting
//
//  主题系统 — 桌布背景 + 餐盘容器 + 食物盘
//  每个主题一套完整资源: tablecloth / plate / food
//

import SwiftUI

// MARK: - Background Type

enum ThemeBackground: Equatable {
    /// Solid color with optional gradient (default style)
    case solid(light: Color, dark: Color)
    /// Image from asset catalog (namespaced under Themes/)
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
    let blendColor: Color
    let fadeStart: CGFloat
    let fadeEnd: CGFloat
    
    // Plate — namespaced asset name
    let plateImage: String?
    let plateScale: CGFloat
    
    // Food plate illustration — namespaced asset name
    let foodImage: String?
    
    // Colors
    let progressColor: Color
    let progressTrackColor: Color
    
    let isPremium: Bool
    
    var hasPlate: Bool { plateImage != nil }
}

// MARK: - Built-in Themes

extension PlateTheme {
    
    /// Default — pure gradient, no plate imagery
    static let minimal = PlateTheme(
        id: "minimal",
        name: "Minimal",
        localizedName: "theme_minimal".localized,
        background: .solid(
            light: Color(red: 0.98, green: 0.98, blue: 1.0),
            dark: Color(red: 0.11, green: 0.11, blue: 0.12)
        ),
        blendColor: .clear,
        fadeStart: 0, fadeEnd: 0,
        plateImage: nil,
        plateScale: 1.0,
        foodImage: nil,
        progressColor: .fastingGreen,
        progressTrackColor: Color.gray.opacity(0.1),
        isPremium: false
    )
    
    /// 白色陶瓷盘 + 格子桌布
    static let ceramicPlaid = PlateTheme(
        id: "ceramicPlaid",
        name: "Ceramic Plaid",
        localizedName: "theme_ceramic_plaid".localized,
        background: .image(assetName: "Themes/CeramicPlaid/tablecloth"),
        blendColor: Color(red: 0.96, green: 0.94, blue: 0.90),
        fadeStart: 0.3, fadeEnd: 0.65,
        plateImage: "Themes/CeramicPlaid/plate",
        plateScale: 1.25,
        foodImage: "Themes/CeramicPlaid/food",
        progressColor: .fastingGreen,
        progressTrackColor: Color.gray.opacity(0.1),
        isPremium: false
    )
    
    /// 红陶雕花盘 + 木纹桌面
    static let terracottaWood = PlateTheme(
        id: "terracottaWood",
        name: "Terracotta Wood",
        localizedName: "theme_terracotta_wood".localized,
        background: .image(assetName: "Themes/TerracottaWood/tablecloth"),
        blendColor: Color(red: 0.12, green: 0.10, blue: 0.08),
        fadeStart: 0.25, fadeEnd: 0.6,
        plateImage: "Themes/TerracottaWood/plate",
        plateScale: 1.25,
        foodImage: "Themes/TerracottaWood/food",
        progressColor: .fastingOrange,
        progressTrackColor: Color.white.opacity(0.08),
        isPremium: false
    )
    
    /// 陶瓷盘 + 大理石桌面
    static let ceramicMarble = PlateTheme(
        id: "ceramicMarble",
        name: "Ceramic Marble",
        localizedName: "theme_ceramic_marble".localized,
        background: .image(assetName: "Themes/CeramicMarble/tablecloth"),
        blendColor: Color(red: 0.92, green: 0.92, blue: 0.93),
        fadeStart: 0.3, fadeEnd: 0.65,
        plateImage: "Themes/CeramicMarble/plate",
        plateScale: 1.25,
        foodImage: "Themes/CeramicMarble/food",
        progressColor: .fastingTeal,
        progressTrackColor: Color.fastingTeal.opacity(0.1),
        isPremium: true
    )
    
    /// 木盘子 + 亚麻桌布
    static let woodLinen = PlateTheme(
        id: "woodLinen",
        name: "Wood Linen",
        localizedName: "theme_wood_linen".localized,
        background: .image(assetName: "Themes/WoodLinen/tablecloth"),
        blendColor: Color(red: 0.95, green: 0.93, blue: 0.88),
        fadeStart: 0.3, fadeEnd: 0.65,
        plateImage: "Themes/WoodLinen/plate",
        plateScale: 1.25,
        foodImage: "Themes/WoodLinen/food",
        progressColor: .fastingGreen,
        progressTrackColor: Color.brown.opacity(0.1),
        isPremium: true
    )
    
    static let allThemes: [PlateTheme] = [.minimal, .ceramicPlaid, .terracottaWood, .ceramicMarble, .woodLinen]
    
    static func theme(for id: String) -> PlateTheme {
        // Migration: map old theme ids to new ones
        switch id {
        case "classic": return .ceramicPlaid
        case "ironwood": return .terracottaWood
        case "marble": return .ceramicMarble
        case "washi": return .woodLinen
        default: break
        }
        return allThemes.first { $0.id == id } ?? .ceramicPlaid
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
        let savedId = UserDefaults.standard.string(forKey: "selectedThemeId") ?? "ceramicPlaid"
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
            (colorScheme == .dark ? Color(.systemBackground) : theme.blendColor)
            
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
