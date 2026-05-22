# Welcome Screen Redesign — Design Document

**Date**: 2026-05-22
**Goal**: Visual refresh of the welcome/login screen (minimal & clean Swiss-medical aesthetic)
**Status**: Approved — ready for implementation

---

## Design Summary

Replace the current green-filled-top + white-bottom-sheet layout with a **single contained white card** centered on a soft off-white background. Green is used only as an accent color. The login flow and all three states (loading, login form, welcome back) remain functionally identical.

---

## Visual Layout

```
┌──────────────────────────────────────────┐
│     AppColors.background (#F7F9F7)       │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │  White card (#FFFFFF), cardShadow  │  │
│  │  max-width ~420dp, centered        │  │
│  │  border-radius: 16dp               │  │
│  │                                    │  │
│  │  ┌── Illustration (140dp) ──┐     │  │
│  │  │  Existing SVG, smaller    │     │  │
│  │  └──────────────────────────┘     │  │
│  │                                    │  │
│  │  🍃 MEDIKU (brand name)           │  │
│  │  Kesehatan keluarga di satu tmpat  │  │
│  │                                    │  │
│  │  ┌ Input: KK/Username ────┐      │  │
│  │  └────────────────────────┘      │  │
│  │  ┌ Input: Password ───────┐      │  │
│  │  └────────────────────────┘      │  │
│  │        Lupa password?            │  │
│  │  ┌ Button: MASUK ────────┐      │  │
│  │  └────────────────────────┘      │  │
│  │   Belum punya akun? Daftar       │  │
│  │       v1.0 (C) 2026 MEDIKU       │  │
│  └────────────────────────────────────┘  │
│                                          │
└──────────────────────────────────────────┘
```

### Key structural changes from current

| Aspect | Current | Proposed |
|---|---|---|
| Root widget | `Stack` + `Positioned` | `Scaffold` + `SingleChildScrollView` |
| Layout split | Green background (top) + white bottom sheet | Single white card, full-screen background |
| Bottom sheet | Drag handle, `AnimatedSlide`, manual keyboard tracking | None — replaced by centered card |
| Keyboard | `resizeToAvoidBottomInset: false`, manual `viewInsets.bottom` | `resizeToAvoidBottomInset: true` (default), native handling |
| `isSmallScreen`/`isShortScreen` conditionals | Inline magic numbers throughout | Use `AppTheme` spacing tokens, no custom breakpoints |

---

## Color System

| Element | Color |
|---|---|
| Scaffold background | `AppColors.background` `#F7F9F7` |
| Card background | `AppColors.card` `#FFFFFF` |
| Card shadow | `AppTheme.cardShadow` |
| Brand "MEDIKU" | `AppColors.primary` `#144425` |
| Tagline | `AppColors.textSecondary` `#6B7A70` |
| Input icons (prefix/suffix) | `AppColors.primary` |
| Input focused border | `AppColors.primary`, width 2 |
| Button background | `AppColors.primary` |
| Button text | `AppColors.textOnPrimary` `#FFFFFF` |
| Link text (forgot pw, register) | `AppColors.primary` |
| "Not you?" logout link | `AppColors.statusRed` `#D94F4F` |
| Version text | `AppColors.textSecondary` |

---

## Typography (AppTheme tokens)

| Element | Token |
|---|---|
| Brand name | `screenTitle` (22px, bold) — was inline 28px |
| Tagline | `bodySmall` (12px, secondary) — was inline 14px |
| Input text | 16px regular (`bodyLarge` sizing) |
| Button text | `buttonText` (16px, semibold) |
| Error dialog title | `screenTitle` (22px) |
| Error dialog body | `bodyLarge` (16px) |
| Links | 14px medium (inline) |
| Version | `bodySmall` (12px) |

---

## States

### 1. Loading
- `CircularProgressIndicator` centered inside the card, `AppColors.primary`
- Replaces card content while `_checkLoginStatus()` runs via `AnimatedSwitcher`

### 2. Login Form
- Default state — no active session
- Full form: illustration + branding + inputs + button + links
- Back arrow hidden

### 3. Welcome Back
- Active session detected
- Illustration stays visible at reduced size (same as login)
- Below: "Selamat datang kembali," + `_userName`
- "LANJUTKAN" button (full-width, primary green, arrow icon)
- "Bukan Anda? Masuk dengan akun lain" red link → triggers logout + re-check
- Version label
- Back arrow top-left → return to login form via `setState`

---

## Animations

| Trigger | Animation | Duration |
|---|---|---|
| Screen mount (card) | Slide up 20dp + fade in, `fastOutSlowIn` | 400ms |
| Screen mount (illustration) | Fade in with slight delay (stagger) | 400ms, 200ms delay |
| Content swap (loading→form/welcome) | `AnimatedSwitcher` crossfade | 300ms |
| Welcome back back-arrow press | Slide transition back to login content | 300ms |

The `AnimatedOpacity` on illustration and `AnimatedSlide` on the bottom sheet from the current code are replaced by the card-level entry animation.

---

## Error Handling

- `_showErrorDialog` unchanged — same AlertDialog with primary-styled "OK" button
- Use `AppTheme.dialogTheme` for styling instead of inline `textScaler` calculations

---

## Accessibility & Edge Cases

- Minimum touch target: 48dp (from `AppTheme.elevatedButtonTheme`)
- 16sp body text minimum for elderly users (from `AppTheme.bodyLarge`)
- `resizeToAvoidBottomInset: true` handles keyboard natively
- `mounted` checks preserved for async safety
- Orientation lock/unlock in `initState`/`dispose` preserved unchanged

---

## What Stays Unchanged

- Login API call (`AuthService.login`)
- Session check logic (`AuthService.getMe`, `AuthService.logout`)
- Role-based routing (`_navigateToPatientDashboard` etc.)
- `ForgotPasswordScreen` and `RegisterScreen` navigation
- `ProfileService.instance.initialize()` calls
- `SystemChrome` orientation/overlay setup in `initState` and `dispose`
