---
name: Corso
description: Barcode lap tracking and reporting for school run clubs
colors:
  track-blue: "oklch(0.5 0.134 242.749)"
  track-blue-deep: "oklch(0.44 0.134 242.749)"
  paper: "oklch(1 0 0)"
  ink: "oklch(0.141 0.005 285.823)"
  cool-mist: "oklch(0.967 0.001 286.375)"
  soft-ink: "oklch(0.552 0.016 285.938)"
  hairline: "oklch(0.92 0.004 286.32)"
  focus-ring: "oklch(0.705 0.015 286.067)"
  alert-red: "oklch(0.577 0.245 27.325)"
typography:
  display:
    fontFamily: "Bricolage Grotesque, Space Grotesk, system-ui, sans-serif"
    fontSize: "clamp(1.75rem, 4vw, 2.75rem)"
    fontWeight: 700
    lineHeight: 1.1
    letterSpacing: "normal"
  body:
    fontFamily: "Space Grotesk, system-ui, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: "1rem"
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: "normal"
  label:
    fontFamily: "Space Grotesk, system-ui, sans-serif"
    fontSize: "0.85rem"
    fontWeight: 600
    lineHeight: 1.3
    letterSpacing: "normal"
rounded:
  default: "0.625rem"
  pill: "999px"
spacing:
  sm: "0.5rem"
  md: "0.85rem"
  lg: "1.5rem"
components:
  button-primary:
    backgroundColor: "{colors.track-blue}"
    textColor: "{colors.paper}"
    rounded: "{rounded.default}"
    padding: "0.6rem 1.1rem"
  button-primary-hover:
    backgroundColor: "{colors.track-blue-deep}"
  button-secondary:
    backgroundColor: "{colors.cool-mist}"
    textColor: "{colors.ink}"
    rounded: "{rounded.default}"
    padding: "0.6rem 1.1rem"
  card:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.ink}"
    rounded: "{rounded.default}"
    padding: "1rem"
---

# Design System: Corso

## 1. Overview

**Creative North Star: "The Track Ledger"**

Corso reads like a well-kept scorer's table at a school athletics carnival: flat, legible surfaces; one confident blue used sparingly for anything actionable; everything else in ink-on-paper neutrals. It is a tool a coach trusts to be correct and fast in the moment, not a showpiece. This session retired the previous "Obsidian Glass" direction (navy backgrounds, gold pill accents, translucent blur panels) in favor of a flat shadcn-based system: the glass, the gold, and the pill-shaped navigation are gone. Nothing here should look like it's trying to sell something to a child or a parent — no gradients standing in for hierarchy, no decorative motion, no dark patterns.

**Key Characteristics:**
- Flat surfaces at rest; no backdrop blur, no glass panels.
- One primary blue, everywhere else is ink, paper, or a hairline of gray.
- Rounded corners are consistent and moderate (0.625rem), not pill-shaped except where a control is genuinely a toggle/switch.
- Dark mode is a first-class second pass, not an inverted filter — its own token set, tuned separately (see Colors).

## 2. Colors

The palette is almost entirely neutral: paper, ink, and one hairline gray carry the vast majority of every screen. Track Blue is the only saturated color, reserved for primary actions and the current selection.

### Primary
- **Track Blue** (oklch(0.5 0.134 242.749) / ≈ #0076c6): primary buttons, the active tab, links, focus accents. Used on the smallest possible surface area — a button's fill, a tab's underline-equivalent — never as a page background.
- **Track Blue Deep** (oklch(0.44 0.134 242.749) / ≈ #005e9e): hover/pressed state for anything using Track Blue.

### Neutral
- **Paper** (oklch(1 0 0) / #ffffff): page and card background.
- **Ink** (oklch(0.141 0.005 285.823) / ≈ #0f1115): primary text, headings.
- **Cool Mist** (oklch(0.967 0.001 286.375) / ≈ #f6f6f7): secondary button fill, subtle panel backgrounds, non-active states. True near-neutral gray — deliberately *not* warm-tinted cream/sand, to avoid reading as a generic AI-template palette.
- **Soft Ink** (oklch(0.552 0.016 285.938) / ≈ #8b8d94): secondary/muted text, captions, helper copy.
- **Hairline** (oklch(0.92 0.004 286.32) / ≈ #e2e2e5): borders, dividers, input strokes.
- **Alert Red** (oklch(0.577 0.245 27.325) / ≈ #d92d20): destructive actions and error states only.

### Named Rules
**The One Blue Rule.** Track Blue is the only saturated color in the system. If a second color feels necessary for emphasis, the answer is weight or size on Ink, not a new hue.

**The Dark Mode Is Not An Invert Rule.** Dark mode redefines every token from scratch (background, card, primary all shift independently) rather than inverting light-mode values — Track Blue itself becomes a more muted navy (oklch(0.443 0.11 240.79)) in dark mode, not the same blue on a dark canvas.

## 3. Typography

**Display Font:** Bricolage Grotesque (with Space Grotesk, system-ui fallback)
**Body Font:** Space Grotesk (with system-ui, -apple-system, Segoe UI fallback)

**Character:** A confident, slightly characterful geometric grotesque for headings paired with its own quieter sibling for body copy — same family lineage, so nothing feels mismatched, but display type is allowed a little more personality than the workmanlike body text.

### Hierarchy
- **Display** (700, `clamp(1.75rem, 4vw, 2.75rem)`, 1.1 line-height): Page-level headings ("Run. Track. Celebrate.", tab section titles). Bricolage Grotesque.
- **Body** (400, 1rem, 1.5 line-height): All paragraph copy, form labels, table content. Space Grotesk. Cap prose width at 65–75ch where it appears in longer blocks (About, Privacy Policy).
- **Label** (600, 0.85rem, 1.3 line-height): Buttons, stat chip labels, small UI text. Space Grotesk, no uppercase tracking — Corso does not use the small-caps "eyebrow" pattern anywhere.

## 4. Elevation

Flat by default. The shadcn pass deliberately reduced shadow depth from the old system's glass panels to near-imperceptible separation — depth is conveyed by a 1px hairline border first, a soft shadow second, and blur never.

### Shadow Vocabulary
- **shadow-sm** (`0 1px 2px rgba(0,0,0,0.05)`): default resting state for cards and panels.
- **shadow-md** (`0 1px 3px rgba(0,0,0,0.08), 0 1px 2px rgba(0,0,0,0.06)`): slightly raised elements (dropdown menus, popovers).

### Named Rules
**The Flat-By-Default Rule.** No `backdrop-filter`, no glass. Surfaces are opaque Paper with a Hairline border; shadows are a whisper, not a statement.

## 5. Components

### Buttons
- **Shape:** rounded corners at 0.625rem (`--radius`), not pill-shaped.
- **Primary:** Track Blue fill, Paper text, no shadow at rest.
- **Hover / Focus:** background shifts to Track Blue Deep; no transform/lift on hover (flat interaction, not a "lift" affordance).
- **Secondary:** Cool Mist fill, Ink text, Hairline border.
- **Destructive:** Paper fill, Alert Red text and border at rest; fills solid Alert Red with Paper text on hover.

### Cards / Containers
- **Corner Style:** 0.625rem radius, matching buttons.
- **Background:** Paper.
- **Shadow Strategy:** shadow-sm at rest; no hover elevation change.
- **Border:** 1px Hairline.
- **Internal Padding:** ~1rem.

### Inputs / Fields
- **Style:** Paper background, 1px Hairline border, 0.625rem radius.
- **Focus:** border shifts to Focus Ring color (oklch(0.705 0.015 286.067)) with a soft 3px outer glow at 35% opacity — no harsh blue focus ring.

### Navigation
- **Style:** the mobile dropdown menu is a flat popover (Paper background, Hairline border, shadow-md) — not the old dark-navy glass panel. Items are plain text/icon rows with a Cool Mist hover state, not pill-shaped buttons.
- **Active tab:** Track Blue fill (light mode) or the dark-mode primary token (dark mode) — routed through the same `--primary` token in both cases, never a hardcoded hex that could drift out of sync between modes.

## 6. Do's and Don'ts

### Do:
- **Do** keep Track Blue to the smallest surface area that still reads as "this is the primary action" — a button fill, an active tab, a focus ring.
- **Do** route every color through the shadcn CSS custom properties (`var(--primary)`, `var(--card)`, `var(--border)`, etc.) rather than hardcoding a hex value, so light/dark mode and future palette tweaks stay in sync automatically.
- **Do** use plain, direct copy — privacy and safety statements ("No ads. No tracking.") are stated outright as UI content, not buried in a footer link.
- **Do** respect `prefers-reduced-motion` for any transition or animation added.

### Don't:
- **Don't** reintroduce glass panels, backdrop blur, or gold pill-shaped navigation — the retired "Obsidian Glass" direction from the previous DESIGN.md.
- **Don't** use a warm cream/sand tint for neutral surfaces "for elegance" — Corso's neutrals are true near-zero-chroma grays (Cool Mist, Hairline), not warm-tinted.
- **Don't** add a second saturated accent color. If something needs to stand out, use Ink weight/size, not a new hue.
- **Don't** use small-caps uppercase-tracked "eyebrow" labels above sections — not part of this system's vocabulary.
- **Don't** build anything that resembles consumer social/ad-driven engagement UI (streaks-as-manipulation, notification badges designed to create anxiety, autoplay, infinite scroll) — this app handles school children's data and the tone is trustworthy/practical, not attention-optimized.
