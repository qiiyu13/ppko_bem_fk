# Metric Hero Animation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Redesign the metric card Hero animation to be smooth, professional, and eliminate choppy motion and content racing issues.

**Architecture:** Replace MaterialRectArcTween with RectTween for straight-line expansion, implement placeholder strategy to prevent layout shift, synchronize detail screen content appearance with Hero completion (60% mark), and add subtle press feedback.

**Tech Stack:** Flutter, Hero widgets, AnimationController, RectTween

---

## Task 1: Update Hero Configuration in home_tab.dart

**Files:**
- Modify: `lib/screens/patient/tabs/home_tab.dart:289-306`

**Step 1: Update the PageRouteBuilder with new duration and curve**

Replace the current navigation code (lines 289-306):

```dart
Navigator.of(context).push(
  PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 500),
    reverseTransitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, animation, secondaryAnimation) {
      return MetricDetailScreen(metric: metric);
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return child;
    },
  ),
);
```

With:

```dart
Navigator.of(context).push(
  PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 700),
    reverseTransitionDuration: const Duration(milliseconds: 500),
    opaque: true,
    pageBuilder: (context, animation, secondaryAnimation) {
      return MetricDetailScreen(
        metric: metric,
        transitionAnimation: animation,
      );
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return child;
    },
  ),
);
```

**Step 2: Update the Hero widget configuration**

Replace the Hero widget (lines 302-306):

```dart
Hero(
  tag: 'metric_${metric.type.name}',
  createRectTween: (begin, end) {
    return MaterialRectArcTween(begin: begin, end: end);
  },
```

With:

```dart
Hero(
  tag: 'metric_${metric.type.name}',
  transitionOnUserGestures: false,
  createRectTween: (begin, end) {
    return RectTween(begin: begin, end: end);
  },
  placeholderBuilder: (context, heroSize, child) {
    return Opacity(
      opacity: 0.3,
      child: child,
    );
  },
  flightShuttleBuilder: (
    flightContext,
    animation,
    flightDirection,
    fromHeroContext,
    toHeroContext,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Material(
          elevation: 24 * animation.value,
          borderRadius: BorderRadius.circular(24),
          child: toHeroContext.widget,
        );
      },
    );
  },
```

**Step 3: Add press feedback to the GestureDetector**

Replace the GestureDetector (line 287-302) to wrap the Hero with a StatefulBuilder for press feedback:

Add a new stateful wrapper around the card content. Create a new variable at the top of `_buildMetricCard`:

```dart
bool _isPressed = false;
```

Then wrap the GestureDetector return with StatefulBuilder:

```dart
return StatefulBuilder(
  builder: (context, setState) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        Navigator.of(context).push(
          // ... navigation code from Step 1
        );
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Hero(
          // ... Hero configuration from Step 2
        ),
      ),
    );
  },
);
```

**Verification:**
- Hero animation should now take 700ms
- Card should have subtle scale effect on press (0.97)
- No arc motion during expansion

---

## Task 2: Update MetricDetailScreen to Accept Animation and Sync Content

**Files:**
- Modify: `lib/screens/patient/metrics/metric_detail_screen.dart:1-50`

**Step 1: Update constructor to accept transition animation**

Replace the class definition (lines 6-16):

```dart
class MetricDetailScreen extends StatefulWidget {
  final HealthMetric metric;

  const MetricDetailScreen({
    super.key,
    required this.metric,
  });
```

With:

```dart
class MetricDetailScreen extends StatefulWidget {
  final HealthMetric metric;
  final Animation<double>? transitionAnimation;

  const MetricDetailScreen({
    super.key,
    required this.metric,
    this.transitionAnimation,
  });
```

**Step 2: Update state to use transition animation for content timing**

Replace the initState and related code (lines 25-45):

```dart
@override
void initState() {
  super.initState();
  _readings = HealthMetricData.getMockHistoryForType(widget.metric.type);
  
  _contentController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  _fadeAnimation = CurvedAnimation(
    parent: _contentController,
    curve: Curves.easeOut,
  );

  // Delay content fade-in until hero animation completes
  Future.delayed(const Duration(milliseconds: 350), () {
    if (mounted) {
      _contentController.forward();
    }
  });
}
```

With:

```dart
@override
void initState() {
  super.initState();
  _readings = HealthMetricData.getMockHistoryForType(widget.metric.type);
  
  _contentController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );
  
  // Use transition animation to drive content appearance
  if (widget.transitionAnimation != null) {
    // Listen to Hero transition and trigger content at 60%
    widget.transitionAnimation!.addListener(_onTransitionUpdate);
  }
}

void _onTransitionUpdate() {
  if (!mounted) return;
  
  final value = widget.transitionAnimation!.value;
  // Start content animation at 60% of Hero completion
  if (value >= 0.6 && _contentController.status == AnimationStatus.dismissed) {
    _contentController.forward();
    widget.transitionAnimation!.removeListener(_onTransitionUpdate);
  }
}

@override
void dispose() {
  widget.transitionAnimation?.removeListener(_onTransitionUpdate);
  _contentController.dispose();
  super.dispose();
}
```

**Step 3: Update close screen to reverse properly**

Replace _closeScreen method (lines 53-62):

```dart
Future<void> _closeScreen() async {
  if (_isClosing) return;
  setState(() => _isClosing = true);

  // Fade out content first
  await _contentController.reverse();
  if (mounted) {
    Navigator.of(context).pop();
  }
}
```

With:

```dart
Future<void> _closeScreen() async {
  if (_isClosing) return;
  setState(() => _isClosing = true);

  // Fade out content first (quicker on close)
  await _contentController.reverse();
  if (mounted) {
    Navigator.of(context).pop();
  }
}
```

**Verification:**
- Screen should accept optional transitionAnimation parameter
- Content should start appearing at 60% of Hero animation (around 420ms)
- No fixed delay - driven by actual animation progress

---

## Task 3: Add Slide-Up Animation to Content in Detail Screen

**Files:**
- Modify: `lib/screens/patient/metrics/metric_detail_screen.dart:75-136`

**Step 1: Create slide animation and update FadeTransition**

After line 21, add:

```dart
late Animation<Offset> _slideAnimation;
```

In initState (after _fadeAnimation setup), add:

```dart
_slideAnimation = Tween<Offset>(
  begin: const Offset(0, 0.05),
  end: Offset.zero,
).animate(CurvedAnimation(
  parent: _contentController,
  curve: Curves.easeOutCubic,
));
```

**Step 2: Replace FadeTransition with combined fade + slide**

Replace lines 79-81:

```dart
Expanded(
  child: FadeTransition(
    opacity: _fadeAnimation,
    child: Container(
```

With:

```dart
Expanded(
  child: AnimatedBuilder(
    animation: _contentController,
    builder: (context, child) {
      return Opacity(
        opacity: _fadeAnimation.value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - _slideAnimation.value.dy * 20)),
          child: child,
        ),
      );
    },
    child: Container(
```

**Verification:**
- Content should slide up from 20px below while fading in
- Animation should feel connected to Hero completion

---

## Task 4: Remove Entrance Animations from Home Grid

**Files:**
- Modify: `lib/screens/patient/tabs/home_tab.dart:221-234`

**Step 1: Verify no entrance animations exist**

Current code (lines 221-234) should already render instantly:

```dart
GridView.count(
  crossAxisCount: 2,
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  crossAxisSpacing: 16,
  mainAxisSpacing: 16,
  childAspectRatio: 1.0,
  children: metrics.map((metric) {
    return _buildMetricCard(
      context: context,
      metric: metric,
      screenWidth: screenWidth,
    );
  }).toList(),
),
```

This is correct - no entrance animation. Just verify this is the current state.

**Step 2: Ensure MiniBarChart renders instantly**

Check MiniBarChart (lines 11-54) - it should already render bars statically with random heights. This is correct.

**Verification:**
- Grid should appear instantly when home screen loads
- No staggered entrance
- Mini bar charts render immediately

---

## Task 5: Test and Verify

**Files:**
- Test: Run app and verify on device/emulator

**Step 1: Run the app**

```bash
flutter run
```

**Step 2: Test the Hero animation**

Navigate to patient home screen and tap on each metric card:

1. **Blood Pressure** - Verify:
   - Card expands over 700ms
   - No arc motion, straight-line expansion
   - Content starts appearing after ~420ms
   - No visual glitches with bottom nav

2. **Cholesterol** - Verify:
   - Same smooth expansion
   - Placeholder visible during transition
   - Press feedback works (subtle scale down)

3. **Blood Sugar** - Verify:
   - Consistent behavior across all cards

4. **Uric Acid** - Verify:
   - Smooth close animation (500ms reverse)
   - Content fades before card shrinks

**Step 3: Verify no entrance animations**

- Navigate to home screen from another tab
- Grid should appear instantly
- No staggered card entrance

**Verification Criteria:**
- [ ] Hero expansion takes ~700ms and feels smooth
- [ ] Content appears after card finishes expanding (no racing)
- [ ] Bottom nav doesn't interfere with animation
- [ ] Press feedback feels immediate
- [ ] Grid appears instantly on home screen
- [ ] Close animation is smooth (500ms)

---

## Implementation Order Summary

1. Task 1: Update Hero configuration in home_tab.dart (duration, curve, placeholder, press feedback)
2. Task 2: Update MetricDetailScreen constructor and initState (animation parameter, timing sync)
3. Task 3: Add slide-up animation to content
4. Task 4: Verify no entrance animations (grid renders instantly)
5. Task 5: Test all interactions

**Estimated Time:** 30-45 minutes
**Risk Level:** Low - focused changes to animation only, no business logic
**Testing:** Manual testing on device required for animation feel
