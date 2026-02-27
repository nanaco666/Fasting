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
- Opacity variations for backgrounds: `Color.fastingGreen.opacity(0.06)` for pill bg, `0.08` for section bg, `0.12` for track.

**Color assignments by domain:**

| Domain | Color | Examples |
|--------|-------|---------|
| Fasting progress | Green | Timer ring, start button, goal checkmark |
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

## 3. Card System — Glass Cards

### GlassCard (primary container)

```swift
.glassCard(cornerRadius: CornerRadius.extraLarge)  // 28pt — standard for all feature cards
```

Implementation: `.ultraThinMaterial` background + shadow `(0.08 light / 0.3 dark, radius: 8, y: 4)`.

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
    static let large: CGFloat = 20    // Sheets (legacy)
    static let extraLarge: CGFloat = 28  // ALL feature cards — the standard
    static let full: CGFloat = 9999   // Capsule buttons
}
```

**Rule:** Feature cards always use `.extraLarge`. Inner elements use `.small` (12pt) or `.medium`.

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
.background(Color.gray.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
```

**Rules:**
- Background: `Color.gray.opacity(0.06)` — NOT the domain color
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
| Toggling, expanding, chevron tap | `Haptic.light()` | Expand card, milestone tap |
| Primary CTA | `Haptic.medium()` | Start fast, connect calendar |
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
    id: String                    // "minimal", "classic", "ironwood"...
    background: ThemeBackground   // .solid / .image / .custom
    plateImage: String?           // Asset name for plate texture
    plateScale: CGFloat           // Plate size relative to dial
    progressColor: Color          // Theme-specific progress ring color
    progressTrackColor: Color     // Theme-specific track color
}
```

### Background Types
- `.solid(light:dark:)` — Pure gradient, original style (Minimal)
- `.image(assetName:)` — Built-in tablecloth texture
- `.custom(fileName:)` — User-uploaded image (future)

### Built-in Themes

| Theme | Background | Plate | Progress Color |
|-------|-----------|-------|---------------|
| Minimal | Solid gradient | None | Green |
| Classic | Linen tablecloth | Cast iron | Green |
| Ironwood | Dark wood | Cast iron | Orange |
| Marble | Marble surface | None | Teal |
| Washi | Japanese paper | Wood | Green |

### Rules
- Plate IS the hero container — no glassCard wrapping the plate
- `plateScale` controls plate-to-dial ratio (1.25 = 25% bigger)
- Image backgrounds fade out via LinearGradient mask (`fadeStart` → `fadeEnd`)
- Widget syncs theme via `themeId` in `SharedFastingState`

---

## 10. Page Architecture

### Tab Structure
```
Fasting (timer) | Plan (calendar + plan + nutrition + fitness)
```

### TimerView Layout
```
TableclothBackground
└── ScrollView
    ├── Timer Card (.extraLarge glass)
    │   ├── plateWithDial (hero)
    │   ├── STARTED / GOAL pills
    │   └── Action button
    ├── Mood Card (.extraLarge glass)
    └── Body Phase Card (.extraLarge glass, expandable)
```

### PlanView Layout
```
GradientBackground
└── ScrollView
    ├── Card 1: Plan Overview (.extraLarge glass)
    │   ├── Header: target icon + "Plan Progress" (green)
    │   ├── Plan name + kg/wk
    │   ├── Stage progress bar + milestone nodes
    │   └── Expanded milestone (progressive disclosure)
    ├── Card 2: Nutrition (.extraLarge glass)
    │   ├── Header: leaf icon + "Daily Nutrition" (orange)
    │   └── CALORIES / PROTEIN / CARB:FIBER pills
    ├── Card 3: Calendar (.extraLarge glass)
    │   ├── Header: calendar icon + "Upcoming" (teal) + "View All"
    │   └── 14-day event list OR connect prompt
    ├── Card 4: Activity (.extraLarge glass)
    │   ├── Header: flame icon + "Today's Activity" (orange)
    │   └── ACTIVE CAL / STEPS pills + workouts
    └── Card 5: Fitness (.extraLarge glass)
        ├── Header: figure.run icon + "Fitness Advice" (teal)
        └── Recommendation list
```

---

## 11. Localization

- All user-facing strings go through `Strings.swift` inline dictionary
- Format: `"key": ["en": "English", "zh-Hans": "中文"]`
- `"key".localized` for simple, `"key".localized(arg1, arg2)` for format strings
- NO hardcoded English in views — everything through `.localized`
- NO emoji in UI — use SF Symbols exclusively

---

## 12. Checklist — Before Shipping Any Screen

- [ ] Colors: only `fastingGreen`/`Teal`/`Orange` + system semantics
- [ ] Typography: max 3 levels visible at once
- [ ] Cards: `.glassCard(cornerRadius: .extraLarge)` with standard header
- [ ] Spacing: 20pt horizontal, 16pt internal, 20pt card gap
- [ ] Animation: spring for user taps, no implicit animations
- [ ] Haptics: every tap has feedback via `Haptic` enum
- [ ] Numbers: `.monospacedDigit()`
- [ ] Dark mode: manually tested
- [ ] Dynamic Type: verified at large sizes
- [ ] Localization: all strings through `.localized`
- [ ] One hero element per screen
- [ ] Progressive disclosure for dense content
