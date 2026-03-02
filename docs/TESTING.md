# Hero Animation Testing Guide

## Task 5: Manual Testing Checklist

### Prerequisites
- Flutter app running on device/emulator
- Patient account logged in
- Navigate to Home screen

### Test Cases

#### 1. Blood Pressure Card
- [ ] Tap Blood Pressure card
- [ ] Verify expansion takes ~700ms (not rushed)
- [ ] Verify no arc motion - straight-line expansion
- [ ] Verify placeholder (30% opacity card) visible during transition
- [ ] Verify content starts appearing after ~420ms (not racing)
- [ ] Verify content slides up from bottom while fading in
- [ ] Close screen - verify reverse animation is smooth (500ms)

#### 2. Cholesterol Card
- [ ] Same tests as Blood Pressure
- [ ] Verify press feedback: card scales to 0.97 on tap
- [ ] Verify elevation shadow grows during expansion

#### 3. Blood Sugar Card
- [ ] Same tests
- [ ] Verify consistent behavior across all cards

#### 4. Uric Acid Card
- [ ] Same tests
- [ ] Verify close animation: content fades before card shrinks

#### 5. Home Grid
- [ ] Navigate to Home tab from another tab
- [ ] Verify cards appear instantly (no stagger)
- [ ] Verify MiniBarChart renders immediately without animation

### Expected Behavior Summary
- Hero expansion: 700ms, smooth, no arc motion
- Content appearance: Starts at 60% of Hero (~420ms)
- Content animation: Fade + slide up 20px
- Press feedback: Immediate scale to 0.97
- Close: 500ms reverse, content fades first
- Grid: Instant appearance, no entrance animation

### Common Issues to Watch For
- [ ] Content racing ahead of Hero expansion
- [ ] Arc motion (choppy) instead of straight line
- [ ] Bottom nav interfering with animation
- [ ] Layout shift (missing placeholder)
- [ ] No press feedback

## All Tasks Complete ✓

1. ✅ Task 1: Hero configuration (700ms, RectTween, placeholder, press feedback)
2. ✅ Task 2: MetricDetailScreen accepts transitionAnimation, syncs at 60%
3. ✅ Task 3: Content slide-up animation (fade + translate)
4. ✅ Task 4: Verified no entrance animations in grid
5. ⏳ Task 5: Manual testing (run tests above)
