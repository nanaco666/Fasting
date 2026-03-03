# Fasting App — Design Architecture

> Single source of truth for all UI decisions.
> Code lives in `UI/Theme/Theme.swift` + `Core/Models/PlateTheme.swift`.
> If this doc and code disagree, update whichever is wrong.

---

## 1. Color Palette — 3 Colors Only

```swift
Color.fastingGreen   // Hero: active state, progress, success, CTAs
Color.fastingTeal    // Accent: secondary actions, calendar, fitness
Color.fastingOrange  // Warning: streaks, calories, meal-related, alerts
```

**Rules:**
- Feature code must NEVER define custom RGB. Use only these 3 + system semantic colors.
- Always prefix with `Color.` in `.fill()`, `.stroke()`, `.foregroundStyle()` — bare `.fastingGreen` fails ShapeStyle inference.
- Dark mode: system handles it. These map to `Color.green`, `.teal`, `.orange`.
- In dark mode, AVOID `.foregroundStyle(.tertiary)` for anything that needs to be read — use `.secondary` minimum.
- Pill/inner backgrounds: `opacity(0.12)` minimum in dark mode (NOT `0.06` — invisible).
- Opacity variations for backgrounds: `Color.fastingGreen.opacity(0.06)` for pill bg, `0.08` for section bg, `0.12` for track.
- **Progress rings and dials read `ThemeManager.shared.currentTheme.progressColor`** — never hardcode `fastingGreen` in dial views.

**Color assignments by domain:**

| Domain | Color | Examples |
|--------|-------|---------|
| Fasting progress | Theme `progressColor` | Timer ring, start button, goal checkmark |
| Plan / Calendar | Teal | Calendar icon, connect prompts, fitness |
| Nutrition / Warning | Orange | Calories, meal events, streaks, stop button |
| Neutral | System grays | `.secondary`, `.tertiary`, `.quaternary` |

---

## 2. Typography — 3 Levels Per Screen, Max

### Type Scale

| Level | Usage | Font |
|-------|-------|------|
| **Hero** | Timer digits, big numbers | `AppFont.hero(56)` — `.system(size: 56, weight: .light, design: .rounded)` |
| **Stat** | Card hero values | `AppFont.stat(34)` — `.system(size: 34, weight: .semibold, design: .rounded)` |
| **Title** | Card headers, section names | `.title3.bold()` or `.title2.weight(.bold)` |
| **Body** | Primary content | `.subheadline.weight(.semibold)` (card header labels) |
| **Supporting** | Descriptions, secondary | `.caption` with `.foregroundStyle(.secondary)` |
| **Micro** | Pill labels, timestamps | `.caption2.weight(.semibold)` + `.tracking(0.5)` + `.tertiary` |

### Minimum Font Sizes
- **Content text** (descriptions, suggestions, event titles): `.subheadline` (15pt) minimum
- **Pill labels**: `.caption` (12pt) — ONLY for UPPERCASE labels with `.tracking(0.5)`
- **Badge text**: `.caption2` (11pt) — ONLY inside colored capsule badges
- **NEVER** use `.caption` or `.caption2` for readable body content

### Rules
- Numbers: always `.monospacedDigit()` — prevents jumping on update
- Timer/countdown: `.contentTransition(.numericText())`
- UPPERCASE micro labels: always add `.tracking(0.5)` to prevent cramped appearance
- No custom fonts — SF Pro system only via dynamic type
- Max 3 distinct sizes visible on any single screen

---

## 3. Card System — Glass & Opaque

### GlassCard (translucent — timer card only)

```swift
.glassCard(cornerRadius: CornerRadius.large)  // 20pt
```

Implementation:
- **Light mode**: `.ultraThinMaterial` background
- **Dark mode**: `Color(white: 0.14)` solid elevated surface (NOT material — too dim)
- Shadow: `0.08 light / 0.4 dark, radius: 8, y: 4`
- **Use case**: Timer card only — allows tablecloth texture to show through

### OpaqueCard (solid — all other cards)

```swift
.opaqueCard(cornerRadius: CornerRadius.large)  // 20pt
```

Implementation:
- **Light mode**: `Color(.secondarySystemBackground)` — fully opaque
- **Dark mode**: `Color(white: 0.14)` — same as glassCard dark
- Shadow: same as glassCard
- **Use case**: Mood card, body phase card, idle card, etc. — no transparency, clean separation from tablecloth

### When to use which
- **Timer card** → `glassCard` (hero element, part of the tablecloth + plate visual)
- **Everything else** → `opaqueCard` (content cards should not show the tablecloth through)

### Card Header Pattern (mandatory for all cards)

Every card follows this header structure:

```swift
HStack(alignment: .firstTextBaseline) {
    Image(systemName: "icon.name")
        .font(.subheadline)
        .foregroundStyle(Color.fastingXxx)       // Card's domain color
    Text("Card Title")
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(Color.fastingXxx)       // Same color
    Spacer()
    Text("trailing info")                         // Optional
        .font(.subheadline)
        .foregroundStyle(.tertiary)
}
.padding(16)
```

### Card Body Padding
- Internal: `16pt` on all sides (header has its own 16pt padding)
- Content below header: `.padding(.horizontal, 16).padding(.bottom, 16)`

### Corner Radius System

```swift
enum CornerRadius {
    static let small: CGFloat = 10    // Chips, badges, inline pills
    static let medium: CGFloat = 16   // Inner containers, record cards
    static let large: CGFloat = 20    // Feature cards — the standard
    static let extraLarge: CGFloat = 28  // Legacy / special cases
    static let full: CGFloat = 9999   // Capsule buttons
}
```

**Rule:** Feature cards use `.large` (20pt). Inner elements use `.small` (10pt) or `.medium` (16pt).

---

## 4. Pill Pattern — Data Display

For compact data display inside cards (macros, stats, time info):

```swift
VStack(spacing: 4) {
    Text("LABEL")
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.tertiary)
        .tracking(0.5)
    HStack(alignment: .lastTextBaseline, spacing: 2) {
        Text("123")
            .font(.title3.bold())
            .monospacedDigit()
        Text("unit")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}
.frame(maxWidth: .infinity)
.padding(.vertical, 12)
.background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
```

**Rules:**
- Background: `Color.gray.opacity(0.1)` — subtle, works in both modes
- Corner radius: `12pt` for pills (hardcoded, not from CornerRadius enum)
- Labels: UPPERCASE, tracking 0.5, `.tertiary`
- Values: `.monospacedDigit()` always

---

## 5. Spacing System

```swift
enum Spacing {
    static let xs: CGFloat = 4     // Icon-to-label gap
    static let sm: CGFloat = 8     // Related elements
    static let md: CGFloat = 16    // Between groups
    static let lg: CGFloat = 24    // Between sections
    static let xl: CGFloat = 32    // Hero element breathing room
    static let xxl: CGFloat = 40   // Page margins (top/bottom)
    static let xxxl: CGFloat = 56  // Special hero spacing
}
```

### Layout Constants (not in Spacing enum)

| Constant | Value | Usage |
|----------|-------|-------|
| Card external horizontal | `20pt` | `.padding(.horizontal, 20)` |
| Card internal padding | `16pt` | `.padding(16)` |
| Card-to-card gap | `20pt` | `VStack(spacing: 20)` |
| Bottom safe area | `40pt` | `.padding(.bottom, 40)` |
| Top content padding | `8pt` | `.padding(.top, 8)` |

**These are the values actually used in TimerView — all cards must match.**

---

## 6. Animation

### Decision Tree

| Trigger | Animation | Constant |
|---------|-----------|----------|
| User tap | `.fastSpring` | `spring(response: 0.3, dampingFraction: 0.7)` |
| State change (no tap) | `.smoothSpring` | `spring(response: 0.5, dampingFraction: 0.8)` |
| Gentle transitions | `.gentleSpring` | `spring(response: 0.6, dampingFraction: 0.85)` |
| Number change | `.contentTransition(.numericText())` | automatic |
| Text change | `.contentTransition(.interpolate)` | automatic |
| Ambient/decorative | `TimelineView(.animation)` | with sin(t) |

### Rules
- NEVER use `.easeInOut` for user-initiated actions — always spring
- NEVER use `.animation(_, value:)` without explicit value (no implicit)
- Max animation duration: 0.5s for response to tap
- Expand/collapse: `.opacity.combined(with: .move(edge: .top))` transition

---

## 7. Haptics

Use `Haptic` enum from `HapticService.swift`:

| Interaction | Call | When |
|------------|------|------|
| Toggling, expanding, chevron tap | `Haptic.light()` | Expand card, milestone tap, theme switch |
| Primary CTA | `Haptic.medium()` | Start fast, connect calendar, switch dial |
| Achievement | `Haptic.success()` | Goal reached, plan created |
| Picker / carousel / date selection | `Haptic.selection()` | Calendar date, month nav |

**Rules:**
- Every interactive element MUST have haptic feedback
- `Haptic.selection()` for continuous browsing (carousel, picker)
- `Haptic.medium()` for commitment actions (start, connect, save)
- `Haptic.light()` for lightweight reveals (expand, info)

---

## 8. Progressive Disclosure

Cards show summary by default. Tap to expand detail.

**Pattern (from TimerView body phase card):**

```swift
// Collapsed: header + one-line summary
// Tapped: expand detail with transition

.transition(.opacity.combined(with: .move(edge: .top)))
.animation(.fastSpring, value: isExpanded)
```

**Where used:**
- Body phase card: tap → full phase timeline
- Plan milestone: tap node → description card
- Mood card: tap → full check-in sheet

---

## 9. Theme System — Plate + Tablecloth

### Architecture

```swift
PlateTheme {
    id: String                    // "minimal", "ceramicPlaid", "terracottaWood"...
    name: String                  // English name
    localizedName: String         // Via "theme_xxx".localized
    background: ThemeBackground   // .solid / .image / .custom
    blendColor: Color             // Base color behind faded image
    fadeStart: CGFloat            // Gradient mask start (0-1)
    fadeEnd: CGFloat              // Gradient mask end (0-1)
    plateImage: String?           // Asset name for plate (e.g. "Themes/CeramicPlaid/plate")
    plateScale: CGFloat           // Plate size relative to dial (1.25 = 25% bigger)
    foodImage: String?            // Asset name for food illustration
    progressColor: Color          // Theme-specific progress ring color
    progressTrackColor: Color     // Theme-specific track color
    isPremium: Bool               // Requires unlock
}
```

### Background Types
- `.solid(light:dark:)` — Pure gradient, original style (Minimal)
- `.image(assetName:)` — Built-in tablecloth texture from asset catalog
- `.custom(fileName:)` — User-uploaded image (stored in documents dir)

### Built-in Themes

| ID | Name | Background | Plate | Progress Color | Premium |
|----|------|-----------|-------|---------------|---------|
| `minimal` | 极简 | Solid gradient | None | Green | No |
| `ceramicPlaid` | 格纹陶瓷 | Plaid tablecloth | Ceramic plate | Green | No |
| `terracottaWood` | 红陶木纹 | Wood texture | Terracotta plate | Orange | No |
| `ceramicMarble` | 大理石 | Marble surface | Ceramic plate | Teal | Yes |
| `woodLinen` | 木盘亚麻 | Linen tablecloth | Wood plate | Green | Yes |

### Asset Naming Convention
All theme assets are namespaced under `Themes/{ThemeId}/`:
- `Themes/CeramicPlaid/tablecloth` — background image
- `Themes/CeramicPlaid/plate` — plate image
- `Themes/CeramicPlaid/food` — food illustration

### Quick Theme Picker
- Toolbar button (🎨 `paintpalette` icon) opens compact sheet
- `QuickThemePickerSheet` — horizontal scroll of theme thumbnails
- Presented at `.height(220)` with NavigationStack + inline title
- Tap to switch and auto-dismiss

### ThemeManager
- Singleton: `ThemeManager.shared`
- Persists to UserDefaults key `"selectedThemeId"`
- `currentTheme` is `@Observable` — views react to changes automatically

### Rules
- Plate IS the hero container — no extra wrapping around the plate
- `plateScale` controls plate-to-dial ratio (1.25 = 25% bigger)
- Image backgrounds fade out via LinearGradient mask (`fadeStart` → `fadeEnd`)
- Widget syncs theme via `themeId` in `SharedFastingState`
- **All 4 dial views** (Simple, Watch, Plate, Solar) read `themeColor` from `ThemeManager.shared.currentTheme.progressColor`
- Timer dial style: long press on dial to cycle (Simple → Clock → Plate → Solar)

---

## 10. Dial Styles

Four switchable timer dials, selectable via long-press gesture:

| Style | File | Characteristics |
|-------|------|----------------|
| **Simple** | `SimpleDialView.swift` | Clean progress ring, large center digits |
| **Clock** | `WatchDialView.swift` | Watch-style with hour ticks, gradient arc |
| **Plate** | `PlateDialView.swift` | Filled sector with plate rim, hour marks |
| **Solar** | `SolarDialView.swift` | Premium dark-mode dial, light wedge effect |

### Rules
- All dials use `themeColor` (from ThemeManager) for progress/accents
- All dials support: progress, elapsed, target, startTime, isFasting, isGoalAchieved
- Persisted via `@AppStorage("timerDialStyle")`
- Transition: `.opacity.combined(with: .scale(scale: 0.95))`

---

## 11. Page Architecture

### Tab Structure
```
Timer (tab 0) | Plan (tab 1)
```

### TimerView Layout
```
TableclothBackground
└── NavigationStack
    └── ScrollView
        ├── Timer Card (.glassCard — hero, translucent)
        │   ├── plateWithDial (theme plate + switchable dial)
        │   ├── STARTED / GOAL pills (editable)
        │   └── Action button (start/stop)
        ├── [Fasting] Mood Card (.opaqueCard)
        ├── [Fasting] Body Phase Card (.opaqueCard, expandable)
        └── [Idle] Body Journey Idle Card (.opaqueCard)
    Toolbar:
        ├── 🎨 Theme Picker (paintpalette)
        └── ⚙️ Settings (gearshape)
```

### PlanView Layout
```
GradientBackground
└── ScrollView
    ├── Card 1: Plan Overview (glass)
    │   ├── Header: target icon + "Plan Progress" (green)
    │   ├── Plan name + kg/wk
    │   ├── Stage progress bar + milestone nodes
    │   └── Expanded milestone (progressive disclosure)
    ├── Card 2: Nutrition (glass)
    │   ├── Header: leaf icon + "Daily Nutrition" (orange)
    │   └── CALORIES / PROTEIN / CARB:FIBER pills
    ├── Card 3: Calendar (glass)
    │   ├── Header: calendar icon + "Upcoming" (teal) + "View All"
    │   └── 14-day event list OR connect prompt
    ├── Card 4: Activity (glass)
    │   ├── Header: flame icon + "Today's Activity" (orange)
    │   └── ACTIVE CAL / STEPS pills + workouts
    └── Card 5: Fitness (glass)
        ├── Header: figure.run icon + "Fitness Advice" (teal)
        └── Recommendation list
```

---

## 12. Localization

- All user-facing strings go through `Strings.swift` inline dictionary
- Format: `"key": ["en": "English", "zh-Hans": "中文"]`
- `"key".localized` for simple, `"key".localized(arg1, arg2)` for format strings
- NO hardcoded English in views — everything through `.localized`
- NO emoji in UI — use SF Symbols exclusively
- Theme names: `theme_minimal`, `theme_ceramic_plaid`, `theme_terracotta_wood`, `theme_ceramic_marble`, `theme_wood_linen`

---

## 13. Checklist — Before Shipping Any Screen

- [ ] Colors: only `fastingGreen`/`Teal`/`Orange` + system semantics
- [ ] Progress: uses `themeColor` from ThemeManager, not hardcoded
- [ ] Typography: max 3 levels visible at once
- [ ] Cards: timer → `.glassCard`, others → `.opaqueCard`, with standard header
- [ ] Spacing: 20pt horizontal, 16pt internal, 20pt card gap
- [ ] Animation: spring for user taps, no implicit animations
- [ ] Haptics: every tap has feedback via `Haptic` enum
- [ ] Numbers: `.monospacedDigit()`
- [ ] Dark mode: manually tested
- [ ] Dynamic Type: verified at large sizes
- [ ] Localization: all strings through `.localized`
- [ ] One hero element per screen
- [ ] Progressive disclosure for dense content
- [ ] Theme color: dials and accent elements follow `progressColor`
