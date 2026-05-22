# Welcome Screen Visual Redesign — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the current green-background + white-bottom-sheet split layout with a single contained white card centered on a soft off-white background.

**Architecture:** Single `Scaffold` with `SingleChildScrollView` wrapping a centered white `Container` (max-width ~420dp). All content — illustration, branding, form/greeting — lives inside the card. `AnimatedSwitcher` handles the three-state content swap (loading, login, welcome-back). Green is accent only. AppTheme tokens used throughout.

**Tech Stack:** Flutter/Dart, `flutter_svg`, existing `AppColors`, `AppTheme`, `AuthService`, `ProfileService` — no new dependencies.

---

### Task 1: Rewrite Widget Structure — Scaffold + Card Shell

**Files:**
- Modify: `lib/screens/welcome_screen.dart` (entire file)

**Step 1: Replace Stack layout with Scaffold + centered card**

Remove: `Stack`, `Positioned`, `_buildGreenBackground`, `_buildBottomSheet`, `_buildLoadingForm`, `_buildLoginForm`, `_buildWelcomeBackSheet` methods. Replace with a single `Scaffold` whose `body` is a `SingleChildScrollView` → `Center` → constrained `Container` (card).

New `build` method skeleton:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppColors.background,
    resizeToAvoidBottomInset: true,
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceXLarge,
            vertical: AppTheme.spaceMedium,
          ),
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 400),
            curve: Curves.fastOutSlowIn,
            offset: _illustrationVisible ? Offset.zero : const Offset(0, 0.05),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: _illustrationVisible ? 1.0 : 0.0,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  boxShadow: AppTheme.cardShadow,
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceXLarge,
                  AppTheme.spaceXXLarge,
                  AppTheme.spaceXLarge,
                  AppTheme.spaceXLarge,
                ),
                child: _buildCardContent(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
```

Note: Keep `SystemChrome.setPreferredOrientations` and `SystemChrome.setSystemUIOverlayStyle` calls in `initState` and `dispose` exactly as-is. Remove `isSmallScreen`, `isShortScreen`, `keyboardHeight`, `sheetHeight` — no longer needed. Class fields `_isLoading`, `_isLoggedIn`, `_userName`, `_userRole`, `_obscurePassword`, `_illustrationVisible` and the two `TextEditingController`s remain.

**Step 2: Verify — run flutter analyze**

```bash
cd /home/qiu/Work/ppko_bem_fk && flutter analyze lib/screens/welcome_screen.dart
```

Expected: No errors (some unused import warnings OK at this stage).

**Step 3: Commit**

```bash
git add lib/screens/welcome_screen.dart
git commit -m "refactor(welcome): replace Stack layout with Scaffold + centered card shell"
```

---

### Task 2: Build Card Content — Illustration + Branding Header

**Files:**
- Modify: `lib/screens/welcome_screen.dart`

**Step 1: Create `_buildBrandingHeader()` and `_buildIllustration()` helper methods**

```dart
Widget _buildIllustration() {
  return SizedBox(
    height: 140,
    child: SvgPicture.asset(
      AssetHelper.getSvgPath('sammy-line-doctor-prescribing-medicine-during-clinical-consultation.svg'),
      fit: BoxFit.contain,
    ),
  );
}

Widget _buildBrandingHeader() {
  return Column(
    children: [
      _buildIllustration(),
      const SizedBox(height: AppTheme.spaceLarge),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            AssetHelper.getIconPath('leaf_icon.png'),
            width: 20,
            height: 20,
            color: AppColors.primary,
            colorBlendMode: BlendMode.srcIn,
          ),
          const SizedBox(width: AppTheme.spaceSmall),
          Text(
            'MEDIKU',
            style: AppTheme.screenTitle.copyWith(
              fontSize: 26,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
      const SizedBox(height: AppTheme.spaceXSmall),
      Text(
        'Kesehatan keluarga di satu tempat',
        style: AppTheme.bodySmall,
      ),
    ],
  );
}
```

**Step 2: Verify — flutter analyze**

```bash
cd /home/qiu/Work/ppko_bem_fk && flutter analyze lib/screens/welcome_screen.dart
```

**Step 3: Commit**

```bash
git add lib/screens/welcome_screen.dart
git commit -m "feat(welcome): add illustration and branding header inside card"
```

---

### Task 3: Build Login Form Content

**Files:**
- Modify: `lib/screens/welcome_screen.dart`

**Step 1: Create `_buildLoginForm()` — uses AppTheme spacing, no `isShortScreen`**

```dart
Widget _buildLoginForm() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextField(
        controller: _identifierController,
        keyboardType: TextInputType.text,
        style: const TextStyle(
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Nomor KK atau Username',
          hintStyle: const TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
          prefixIcon: const Icon(
            Icons.person_outline,
            color: AppColors.primary,
          ),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMedium,
            vertical: 14,
          ),
        ),
      ),
      const SizedBox(height: AppTheme.spaceLarge),
      TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: const TextStyle(
          fontSize: 16,
          letterSpacing: 1.5,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Password',
          hintStyle: const TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
          prefixIcon: const Icon(
            Icons.lock_outlined,
            color: AppColors.primary,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: AppColors.textSecondary,
            ),
            onPressed: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMedium,
            vertical: 14,
          ),
        ),
      ),
      const SizedBox(height: AppTheme.spaceMedium),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: _showForgotPasswordDialog,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Lupa password?',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      const SizedBox(height: AppTheme.spaceMedium),
      SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: () async {
            final identifier = _identifierController.text.trim();
            final password = _passwordController.text;
            if (identifier.isEmpty) {
              _showErrorDialog('Nomor KK atau Username tidak boleh kosong');
              return;
            }
            if (password.isEmpty) {
              _showErrorDialog('Password tidak boleh kosong');
              return;
            }
            try {
              final data = await AuthService.login(
                identifier: identifier,
                password: password,
              );
              if (mounted) {
                final role = data['user']?['role'] ?? 'PATIENT';
                if (role == 'ADMIN') {
                  await _navigateToAdminDashboard();
                } else if (role == 'SUPERADMIN') {
                  await _navigateToSuperadminDashboard();
                } else {
                  await _navigateToPatientDashboard();
                }
              }
            } catch (e) {
              if (mounted) {
                _showErrorDialog('Login gagal. Periksa kembali KK/Username dan password Anda.');
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
          child: const Text(
            'MASUK',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
      const SizedBox(height: AppTheme.spaceLarge),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Belum punya akun?',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RegisterScreen(),
                ),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Daftar',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
```

**Step 2: Verify — flutter analyze**

```bash
cd /home/qiu/Work/ppko_bem_fk && flutter analyze lib/screens/welcome_screen.dart
```

**Step 3: Commit**

```bash
git add lib/screens/welcome_screen.dart
git commit -m "feat(welcome): build login form with AppTheme tokens, no size breakpoints"
```

---

### Task 4: Build Welcome Back Content

**Files:**
- Modify: `lib/screens/welcome_screen.dart`

**Step 1: Create `_buildWelcomeBackContent()` — greeting + proceed button + logout link**

```dart
Widget _buildWelcomeBackContent() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Back arrow to return to login form
      Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
          onPressed: () {
            setState(() => _isLoggedIn = false);
          },
        ),
      ),
      const SizedBox(height: AppTheme.spaceMedium),
      const Text(
        'Selamat datang kembali,',
        style: TextStyle(
          fontSize: 18,
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(height: AppTheme.spaceXSmall),
      Text(
        _userName,
        style: AppTheme.screenTitle.copyWith(
          fontSize: 28,
          height: 1.1,
        ),
      ),
      const SizedBox(height: AppTheme.spaceXXLarge),
      SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () {
            if (_userRole == 'ADMIN') {
              _navigateToAdminDashboard();
            } else if (_userRole == 'SUPERADMIN') {
              _navigateToSuperadminDashboard();
            } else {
              _navigateToPatientDashboard();
            }
          },
          icon: const Icon(Icons.arrow_forward, size: 18),
          label: const Text(
            'LANJUTKAN',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
        ),
      ),
      const SizedBox(height: AppTheme.spaceXLarge),
      Center(
        child: TextButton(
          onPressed: () async {
            setState(() => _isLoading = true);
            await AuthService.logout();
            await _checkLoginStatus();
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text(
            'Bukan Anda? Masuk dengan akun lain',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.statusRed,
            ),
          ),
        ),
      ),
    ],
  );
}
```

**Step 2: Verify — flutter analyze**

**Step 3: Commit**

```bash
git add lib/screens/welcome_screen.dart
git commit -m "feat(welcome): build welcome-back content with back arrow and button icon"
```

---

### Task 5: Assemble Card Content + AnimatedSwitcher

**Files:**
- Modify: `lib/screens/welcome_screen.dart`

**Step 1: Create `_buildCardContent()` — dispatches to loading/login/welcome-back**

```dart
Widget _buildCardContent() {
  return AnimatedSwitcher(
    duration: const Duration(milliseconds: 300),
    child: _isLoading
        ? const SizedBox(
            key: ValueKey('loading'),
            height: 200,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        : _isLoggedIn
            ? Column(
                key: const ValueKey('welcome'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBrandingHeader(),
                  _buildWelcomeBackContent(),
                  const SizedBox(height: AppTheme.spaceXLarge),
                  Center(
                    child: Text(
                      'v1.0 © 2026 MEDIKU',
                      style: AppTheme.bodySmall,
                    ),
                  ),
                ],
              )
            : Column(
                key: const ValueKey('login'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBrandingHeader(),
                  const SizedBox(height: AppTheme.spaceXLarge),
                  _buildLoginForm(),
                  const SizedBox(height: AppTheme.spaceMedium),
                  Center(
                    child: Text(
                      'v1.0 © 2026 MEDIKU',
                      style: AppTheme.bodySmall,
                    ),
                  ),
                ],
              ),
  );
}
```

**Step 2: Wire `_buildCardContent()` into the `build` method** — replace placeholder `_buildCardContent()` call from Task 1.

**Step 3: Remove unused methods** — delete old `_buildGreenBackground`, `_buildBottomSheet`, `_buildWelcomeBackSheet`, `_buildLoadingForm`, `_buildLoginForm`. Remove unused `_userRole` field if it was only in old bottom sheet method (keep it — needed for `_buildWelcomeBackContent` and the old `_navigateTo*` helpers).

Remove `_illustrationVisible` field — inline the animation to always play on mount (use `initState` + `Future.delayed` or `WidgetsBinding.instance.addPostFrameCallback`). Actually, keep `_illustrationVisible` — it's already set to `true` in `_checkLoginStatus`, which triggers the entry animation. That works.

**Step 4: Verify — flutter analyze**

```bash
cd /home/qiu/Work/ppko_bem_fk && flutter analyze lib/screens/welcome_screen.dart
```

Expected: 0 errors, 0 warnings.

**Step 5: Commit**

```bash
git add lib/screens/welcome_screen.dart
git commit -m "feat(welcome): wire card content with AnimatedSwitcher, remove old layout methods"
```

---

### Task 6: Final Cleanup — Remove Unused Fields, Fix Error Dialog

**Files:**
- Modify: `lib/screens/welcome_screen.dart`

**Step 1: Clean up `_showErrorDialog`** — use `AppTheme.dialogTheme` styling instead of manual `textScaler` multiplication, or keep it simple with a standard `AlertDialog`:

```dart
void _showErrorDialog(String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Error'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
```

**Step 2: Review class fields** — verify `_obscurePassword`, `_isLoading`, `_isLoggedIn`, `_userName`, `_userRole`, `_illustrationVisible` are all used. None of the old `isSmallScreen`/`isShortScreen`/`keyboardHeight`/`sheetHeight` locals exist (already removed from `build`).

**Step 3: Verify — flutter analyze**

```bash
cd /home/qiu/Work/ppko_bem_fk && flutter analyze lib/screens/welcome_screen.dart
```

Expected: 0 errors, 0 warnings.

**Step 4: Commit**

```bash
git add lib/screens/welcome_screen.dart
git commit -m "chore(welcome): simplify error dialog, remove unused locals"
```

---

### Task 7: Run Full Project Analysis

**Step 1: Full flutter analyze**

```bash
cd /home/qiu/Work/ppko_bem_fk && flutter analyze
```

Expected: 0 errors from the project (any pre-existing warnings ignored if not in welcome_screen.dart).

**Step 2: Check for any import issues** — ensure all imports at top of file are still valid. The imports should be:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../screens/patient/patient_main_screen.dart';
import '../screens/admin/admin_main_screen.dart';
import '../screens/superadmin/superadmin_main_screen.dart';
import '../screens/register_screen.dart';
import 'forgot_password_screen.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../utils/asset_helper.dart';
```

**Step 3: Commit final**

```bash
git add lib/screens/welcome_screen.dart
git commit -m "chore(welcome): final cleanup, verify imports"
```

---
