# Metric Card Hero Animation Redesign

## Problem Statement

The current Hero animation when tapping a metric card has several issues:

1. **Rushed Animation** - 500ms duration feels hurried and unpolished
2. **Content Racing** - Detail screen content starts fading in at 350ms, competing with the card expansion
3. **Choppy Motion** - Uses `MaterialRectArcTween` which creates an awkward arc path
4. **Layering Issues** - Card expansion conflicts with bottom navigation bar, creating visual clutter

## Design Solution

### Hero Transition

**Duration**: 700ms (professional, deliberate pace)

**Motion**: 
- Replace `MaterialRectArcTween` with `RectTween` for straight-line expansion
- Use `Curves.fastOutSlowIn` - starts quick, ends smooth
- Maintain aspect ratio during expansion for natural feel

**Placeholder Strategy**:
- Keep original card visible with reduced opacity (0.3) during transition
- Prevents layout shift and "hole" in the grid
- Placeholder fades out as Hero card expands

**Elevation & Layering**:
- Hero card uses elevation 24 (above bottom nav)
- Add subtle shadow that grows during expansion
- Bottom nav stays at elevation 8 (below Hero)

### Content Synchronization

**Timing**:
- Detail screen content starts appearing at 60% of Hero completion (~420ms)
- Content animation: 350ms fade-in + slide-up from 20px
- Prevents the "racing" effect where stats appear too early

**Visual Hierarchy**:
1. Hero card expands (0-700ms)
2. Background color fills screen (400-700ms)
3. Content fades and slides up (420-770ms)
4. Header stats already visible (part of Hero)
5. Chart and history fade in last

### Card Interaction

**Press Feedback** (instant, no animation delay):
- Scale down to 0.97 on press start
- Return to 1.0 on release
- Duration: 100ms
- Creates tactile feel without slowing interaction

### No Entrance Animations

Per requirements:
- Grid cards appear instantly on home screen load
- No stagger, no fade, no slide
- Immediate, static appearance
- Mini bar charts render instantly without animation

## Files to Modify

1. `lib/screens/patient/tabs/home_tab.dart` - Hero configuration, placeholder
2. `lib/screens/patient/metrics/metric_detail_screen.dart` - Content sync, timing

## Technical Notes

- Use `HeroMode` widget to control Hero availability
- Implement `HeroPlaceholderBuilder` for smooth placeholder
- Add `AnimatedBuilder` for content synchronization
- Ensure proper `Material` widget wrapping for elevation

## Success Criteria

- [ ] Hero expansion feels smooth and deliberate (not rushed)
- [ ] Content appears after card finishes expanding (no racing)
- [ ] No visual conflicts with bottom navigation bar
- [ ] Placeholder prevents layout shift during transition
- [ ] Press feedback feels immediate and tactile
- [ ] No entrance animations on home screen (instant appearance)
