---
version: alpha
name: Masjid Timer
description: Calm, legible prayer-time UI. Midnight navy for structure, gold only for the next jamat.
colors:
  primary: "#1B2A4A"
  on-primary: "#FFFFFF"
  primary-container: "#E4E9F2"
  on-primary-container: "#1B2A4A"
  accent: "#C8A24A"
  on-accent: "#1B2A4A"
  accent-container: "#F6EDD6"
  on-accent-container: "#5E4612"
  background: "#F7F6F2"
  surface: "#FFFFFF"
  surface-variant: "#EFEEE9"
  on-surface: "#151C2B"
  on-surface-variant: "#545C6B"
  outline: "#D6D9DF"
  verified: "#1E7A4F"
  verified-container: "#E3F2EA"
  error: "#B3261E"
  dark-primary: "#AFC2EA"
  dark-on-primary: "#0D1321"
  dark-primary-container: "#24345A"
  dark-accent: "#D9B65E"
  dark-on-accent: "#0D1321"
  dark-accent-container: "#3A2F14"
  dark-on-accent-container: "#F1DDA6"
  dark-background: "#0D1321"
  dark-surface: "#151D2E"
  dark-surface-variant: "#1E2840"
  dark-on-surface: "#E8EBF2"
  dark-on-surface-variant: "#A3ABBD"
  dark-outline: "#2E3A55"
  dark-verified: "#6FCF9C"
  dark-verified-container: "#12301F"
  dark-error: "#F2B8B5"
typography:
  display:
    fontFamily: Manrope
    fontSize: 32px
    fontWeight: 800
    lineHeight: 1.15
  headline:
    fontFamily: Manrope
    fontSize: 24px
    fontWeight: 700
    lineHeight: 1.2
  title:
    fontFamily: Manrope
    fontSize: 18px
    fontWeight: 700
    lineHeight: 1.3
  body:
    fontFamily: Manrope
    fontSize: 15px
    fontWeight: 500
    lineHeight: 1.5
  label:
    fontFamily: Manrope
    fontSize: 13px
    fontWeight: 600
    lineHeight: 1.3
  caption:
    fontFamily: Manrope
    fontSize: 12px
    fontWeight: 500
    lineHeight: 1.35
  time-lg:
    fontFamily: Manrope
    fontSize: 28px
    fontWeight: 800
    lineHeight: 1.1
  time:
    fontFamily: Manrope
    fontSize: 17px
    fontWeight: 700
    lineHeight: 1.2
  name-arabic:
    fontFamily: Noto Naskh Arabic
    fontSize: 18px
    fontWeight: 600
    lineHeight: 1.6
  name-urdu:
    fontFamily: Noto Nastaliq Urdu
    fontSize: 17px
    fontWeight: 600
    lineHeight: 2.0
rounded:
  sm: 8px
  md: 12px
  lg: 16px
  full: 999px
spacing:
  xs: 4px
  sm: 8px
  md: 12px
  lg: 16px
  xl: 24px
  xxl: 32px
  page: 20px
components:
  masjid-card:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
    typography: "{typography.title}"
    rounded: "{rounded.lg}"
    padding: 12px
  prayer-row:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
    typography: "{typography.body}"
    height: 56px
    padding: 16px
  prayer-row-next:
    backgroundColor: "{colors.accent-container}"
    textColor: "{colors.on-accent-container}"
    typography: "{typography.time}"
    height: 56px
    padding: 16px
  next-jamat-banner:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.time-lg}"
    rounded: "{rounded.lg}"
    padding: 16px
  badge-verified:
    backgroundColor: "{colors.verified-container}"
    textColor: "{colors.verified}"
    typography: "{typography.caption}"
    rounded: "{rounded.full}"
    padding: 4px 10px
  badge-community:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface-variant}"
    typography: "{typography.caption}"
    rounded: "{rounded.full}"
    padding: 4px 10px
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.label}"
    rounded: "{rounded.md}"
    height: 48px
  state-view:
    backgroundColor: "{colors.background}"
    textColor: "{colors.on-surface-variant}"
    typography: "{typography.body}"
    padding: 24px
  offline-banner:
    backgroundColor: "{colors.surface-variant}"
    textColor: "{colors.on-surface}"
    typography: "{typography.label}"
    height: 40px
    padding: 12px
---

## Overview
- Calm, quiet and trustworthy. Users glance at it on the way to the masjid.
- Navy carries the structure. Gold means exactly one thing: the **next jamat**.
- Times are the hero. Everything else is secondary.

## Colors
- Light and dark tokens are above. In Flutter, the `dark-*` tokens map to the dark `ColorScheme` and `ThemeExtension`.
- Gold `accent` is used as a fill with navy text. Never put gold text on a light surface (it fails contrast).
- `verified` green is only for the verified badge. Community items use neutral outlines, not a color.
- Text contrast is ≥ 4.5:1 in both themes, including captions.
- Contrast is enforced, not eyeballed: `packages/ui/test/theme_contrast_test.dart` checks every text-on-background pair (on-surface/surface, on-surface/background, on-surface-variant/surface, on-primary/primary, on-accent/accent, on-accent-container/accent-container, verified/verified-container, error/surface) in light and dark. Change a token, the test tells you if it broke.
- The misconfigured screen (no Supabase keys in the build) is the only place colors may be literal, because it renders before the theme exists.

## Typography
- Latin text is Manrope. Every time uses `FontFeature.tabularFigures()` so digits don't shift.
- Arabic names use Noto Naskh Arabic. Urdu names use Noto Nastaliq Urdu, which needs its taller line height.
- Pick the name font from `masjids.name_script`. If it's null, detect from the Unicode range (U+0600–U+06FF).
- Times show as `h:mm` plus a smaller AM/PM, following the device's 12/24-hour setting.
- Fonts are bundled in `apps/masjid_timer/assets/fonts/` (Manrope, Noto Naskh Arabic, Noto Nastaliq Urdu, with their OFL licence files). No `google_fonts`: a first launch offline must still render in the right font, and widget tests must not hit the network.

## Layout
- 4px base grid. Page padding is `spacing.page`. Gap between list cards is `spacing.sm`.
- Mobile first (390px wide). Web content is max 1180px, and lists become a two-column list + map at ≥ 900px.
- Touch targets ≥ 48px.
- Responsive sizes every main screen is smoke-tested at: 360×800 (small Android), 390×844 (design width), 900×1024 (two-column breakpoint), 1440×900 (desktop web). No overflow, no exception, at 1.0 and 2.0 text scale.
- Header actions adapt: labelled buttons at ≥ 900px, icon buttons with a tooltip below that. A screen's actions never carry over to the next screen.

## Elevation & Depth
- Mostly flat: 1px `outline` borders on cards.
- Only the next-jamat banner and map overlays get a soft shadow (blur 16, 6% opacity).
- In dark mode, depth comes from the surface steps (`background` → `surface` → `surface-variant`), not shadows.

## Shapes
- Cards and banner `rounded.lg`, buttons and inputs `rounded.md`, badges and chips `rounded.full`.

## Components
- **Masjid card**
  - Leading 40px index or icon tile, then name and "distance · walking time".
  - Source badge below the name; next namaz name and time on the trailing side.
  - The whole card is one tap target.
- **Prayer-time row**
  - Three columns: namaz (label + source badge), azaan (`on-surface-variant`), jamat (`time` style, end-aligned).
  - Missing time shows "—" plus a "Suggest" link.
- **Next-jamat highlight**
  - On the nearby screen: a navy banner with namaz · time, the masjid, and a countdown pill ("18 min").
  - On masjid detail: that row uses `prayer-row-next` with a "Next · in 18 min" caption.
  - Never more than one highlight per screen.
- **Verified badge**
  - Check icon + "Verified · 3 Nov" on `verified-container`.
  - Community version: outline border + "Community · 2 days ago". Add "May be outdated" in `error` when the staleness rule fires.
- **Arabic or Urdu names**
  - Wrap in `Directionality(TextDirection.rtl)` and align to the start in RTL.
  - If the masjid has both, show the Latin name as the title and the local-script name as a second line.
  - Distance and times keep their LTR layout.

- **Loading, empty and error states** (shared `StateView` in `packages/ui`, used by every `AsyncValue.when`)
  - Loading: skeleton rows the shape of the real content (masjid cards, prayer rows). A spinner only for under-a-second actions inside a button.
  - Empty: one outlined icon, one sentence that says what's missing, one action. "No masjids within 3 km" + "Search a wider area". "No time yet" + "Suggest a time".
  - Error: a plain-language message for a non-technical reader ("Couldn't reach the server. Check your connection and try again.") + Retry. The raw error sits behind a collapsed "Technical details" line, so a screenshot of a bug report still carries it.
  - Permission denied (RLS said no): "You don't have permission to do that", never the Postgres text.
  - Session expired: "Please sign in again" with a Sign in button.
- **Offline banner**
  - A thin `offline-banner` strip under the app bar while there's no connection; cached content stays visible below it. Disappears on reconnect. No modal.
- **Settings**
  - Theme as a three-way segmented control (System · Light · Dark), System default.
  - The version line (`1.2.0+14 · patch 3`) is `caption` in `on-surface-variant`, at the bottom, selectable so it can be copied into a bug report.

## Do's and Don'ts
- Do read every color, size and radius from tokens (`context.tokens`, `AppSpacing`, `AppRadius`).
- Do always show where a time came from (its source) and when it was updated.
- Do test every screen in dark mode, at 200% text scale, and with an Urdu masjid name. The widget smoke tests cover this; add each new screen to them.
- Do write error and empty-state copy for someone on the way to the masjid, not for a developer.
- Don't use gold for anything except the next jamat.
- Don't show a community time styled as if it were verified.
- Don't use emoji, gradients or decorative mosque clip-art. Icons are outlined, 20–24px.
- Don't truncate masjid names to one line. Allow two lines, then an ellipsis.
- Don't show a blank screen for any state. Every async view is loading, content, empty or error.
- Don't use `EdgeInsets.only(left/right)` or `Alignment.centerLeft`. Use the directional versions so RTL names lay out correctly.
