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

## Typography
- Latin text is Manrope. Every time uses `FontFeature.tabularFigures()` so digits don't shift.
- Arabic names use Noto Naskh Arabic. Urdu names use Noto Nastaliq Urdu, which needs its taller line height.
- Pick the name font from `masjids.name_script`. If it's null, detect from the Unicode range (U+0600–U+06FF).
- Times show as `h:mm` plus a smaller AM/PM, following the device's 12/24-hour setting.

## Layout
- 4px base grid. Page padding is `spacing.page`. Gap between list cards is `spacing.sm`.
- Mobile first (390px wide). Web content is max 1180px, and lists become a two-column list + map at ≥ 900px.
- Touch targets ≥ 48px.

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

## Do's and Don'ts
- Do read every color, size and radius from tokens (`context.tokens`, `AppSpacing`, `AppRadius`).
- Do always show where a time came from (its source) and when it was updated.
- Do test every screen in dark mode, at 200% text scale, and with an Urdu masjid name.
- Don't use gold for anything except the next jamat.
- Don't show a community time styled as if it were verified.
- Don't use emoji, gradients or decorative mosque clip-art. Icons are outlined, 20–24px.
- Don't truncate masjid names to one line. Allow two lines, then an ellipsis.
