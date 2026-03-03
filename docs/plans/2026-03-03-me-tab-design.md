# Me Tab Design

## Overview

New third tab "我" (Me) — user profile, plate collection showcase, and settings. Replaces the gear icon in TimerView toolbar as the sole settings entry point.

## Tab Registration

- Tab index: 2 (after Timer=0, Plan=1)
- Icon: `person.crop.circle`
- Label: "我" (localized key `tab_me`)
- Background: plain white (like PlanView), NOT tablecloth theme

## Page Structure

Single `ScrollView` inside `NavigationStack`, three sections top to bottom:

```
NavigationStack {
    ScrollView {
        1. Profile Card
        2. Plate Cabinet
        3. Settings Sections
    }
    .navigationTitle("我")
}
```

## Section 1: Profile Card

**Layout**: Centered VStack inside `.glassCard()`.

- 80pt circular avatar (clip to circle)
- Display name below avatar
- Tap avatar → `PhotosPicker` to select image
- Tap name → sheet with TextField to edit

**Default state** (nothing set):
- `person.crop.circle.fill` placeholder, 80pt, `.tertiary` color
- "点击设置名称" caption text

**Data storage**:
- `displayName: String` — UserDefaults key `"user_display_name"`
- Avatar image — saved to `Documents/profile/avatar.jpg`
- Local-only for now; future migration to server account system

## Section 2: Plate Cabinet

**Visual**: Skeuomorphic wooden display cabinet.

- Outer frame: dark brown rounded rectangle (`cornerRadius: .extraLarge`), simulating cabinet body
- Back panel: warm beige fill + subtle `NoiseTexture` overlay
- Shelves: horizontal divider lines with drop shadow between rows, simulating wooden shelf boards
- Grid: `LazyVGrid`, 3 columns

**Plate states**:
- Collected: theme's `plateImage` thumbnail with slight shadow, displayed on shelf
- Locked: gray circle + `lock.fill` icon, `opacity(0.3)`

**Data (static placeholder)**:
- Show all 5 theme plates (minimal uses a generic plate icon since it has no plate image)
- First 2 marked collected (ceramicPlaid, terracottaWood — the free themes)
- Remaining 3 locked
- No unlock/claim logic — future feature tied to plan completion

**Footer**: "完成计划解锁更多盘子" caption, `.secondary` color

## Section 3: Settings

Migrated from existing `SettingsView.swift`. Each group wrapped in `.glassCard()`.

**Groups**:
1. **断食设置**: Default preset picker, notification toggle
2. **外观**: Theme picker, dark mode (system/light/dark), language
3. **数据**: Apple Health sync status, iCloud sync status
4. **关于**: App version

**Implementation**: Refactor SettingsView content into embeddable `SettingsSections` component. Delete gear icon NavigationLink from TimerView toolbar.

## New Files

| File | Purpose |
|------|---------|
| `Features/Me/MeView.swift` | Main Me tab view |
| `Features/Me/ProfileCardView.swift` | Avatar + name card |
| `Features/Me/PlateCabinetView.swift` | Skeuomorphic plate showcase |
| `Features/Me/EditNameSheet.swift` | Name editing sheet |

## Modified Files

| File | Change |
|------|--------|
| `App/FastingApp.swift` | Add third tab |
| `Features/Timer/TimerView.swift` | Remove gear toolbar item |
| `Features/Timer/SettingsView.swift` | Refactor into embeddable sections |
| `Core/Localization/Strings.swift` | Add `tab_me` and cabinet strings |

## Design Tokens Used

- Cards: `.glassCard(cornerRadius: .large)`
- Spacing: `Spacing.md` (16), `Spacing.lg` (24), `Spacing.xl` (32)
- Corner radius: `CornerRadius.large` (20), `CornerRadius.extraLarge` (28)
- Typography: `.caption.weight(.semibold)` for section headers
- Colors: 3-color palette only (`.fastingGreen`, `.fastingTeal`, `.fastingOrange`)
- Cabinet wood tones: `Color.brown` variants, not new palette colors
