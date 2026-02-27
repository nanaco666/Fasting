//
//  PlateTheme.swift
//  Fasting
//
//  餐盘主题系统 — 盘子 + 桌布
//  本质：换图 + 配色联动
//

import SwiftUI

// MARK: - Theme Definition

struct PlateTheme: Identifiable, Equatable {
    let id: String
    let name: String
    let localizedName: String
    
    // Tablecloth (background)
    let tableclothImage: String       // Asset name
    let tableclothTint: Color         // Fallback tint if no image
    
    // Plate (dial)
    let plateImage: String?           // Optional overlay texture for dial
    let plateRimColor: Color          // Rim/border of the dial
    let plateSurfaceColor: Color      // Dial background fill
    
    // Accent colors derived from theme
    let progressColor: Color          // Arc fill
    let progressTrackColor: Color     // Arc track
    let textPrimaryColor: Color?      // Override for hero text (nil = system)
    
    // Metadata
    let isPremium: Bool
}

// MARK: - Built-in Themes

extension PlateTheme {
    
    /// Default — clean white ceramic on linen
    static let classic = PlateTheme(
        id: "classic",
        name: "Classic",
        localizedName: "theme_classic".localized,
        tableclothImage: "tablecloth_linen",
        tableclothTint: Color(red: 0.96, green: 0.94, blue: 0.90),
        plateImage: nil,
        plateRimColor: Color.gray.opacity(0.15),
        plateSurfaceColor: Color.white.opacity(0.9),
        progressColor: Color.fastingGreen,
        progressTrackColor: Color.gray.opacity(0.1),
        textPrimaryColor: nil,
        isPremium: false
    )
    
    /// Dark wood table + cast iron plate
    static let ironwood = PlateTheme(
        id: "ironwood",
        name: "Ironwood",
        localizedName: "theme_ironwood".localized,
        tableclothImage: "tablecloth_darkwood",
        tableclothTint: Color(red: 0.15, green: 0.12, blue: 0.10),
        plateImage: "plate_castiron",
        plateRimColor: Color.gray.opacity(0.3),
        plateSurfaceColor: Color(red: 0.18, green: 0.18, blue: 0.18),
        progressColor: Color.fastingOrange,
        progressTrackColor: Color.white.opacity(0.08),
        textPrimaryColor: Color.white,
        isPremium: false
    )
    
    /// Marble surface + blue enamel plate
    static let marble = PlateTheme(
        id: "marble",
        name: "Marble",
        localizedName: "theme_marble".localized,
        tableclothImage: "tablecloth_marble",
        tableclothTint: Color(red: 0.92, green: 0.92, blue: 0.93),
        plateImage: nil,
        plateRimColor: Color.fastingTeal.opacity(0.3),
        plateSurfaceColor: Color(red: 0.93, green: 0.95, blue: 0.97),
        progressColor: Color.fastingTeal,
        progressTrackColor: Color.fastingTeal.opacity(0.1),
        textPrimaryColor: nil,
        isPremium: false
    )
    
    /// Japanese washi paper + wooden plate
    static let washi = PlateTheme(
        id: "washi",
        name: "Washi",
        localizedName: "theme_washi".localized,
        tableclothImage: "tablecloth_washi",
        tableclothTint: Color(red: 0.95, green: 0.93, blue: 0.88),
        plateImage: "plate_wood",
        plateRimColor: Color.brown.opacity(0.2),
        plateSurfaceColor: Color(red: 0.85, green: 0.78, blue: 0.65),
        progressColor: Color.fastingGreen,
        progressTrackColor: Color.brown.opacity(0.1),
        textPrimaryColor: nil,
        isPremium: true
    )
    
    /// All available themes
    static let allThemes: [PlateTheme] = [.classic, .ironwood, .marble, .washi]
    
    /// Find by id
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
}

// MARK: - Tablecloth Background View

struct TableclothBackground: View {
    let theme: PlateTheme
    var fadeHeight: CGFloat = 0.6  // 0-1, how far down the fade extends
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Tint fallback (always present)
                theme.tableclothTint
                
                // Image overlay with fade
                if let uiImage = UIImage(named: theme.tableclothImage) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .mask(
                            LinearGradient(
                                stops: [
                                    .init(color: .white, location: 0),
                                    .init(color: .white, location: fadeHeight * 0.6),
                                    .init(color: .clear, location: fadeHeight)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            }
        }
        .ignoresSafeArea()
    }
}
