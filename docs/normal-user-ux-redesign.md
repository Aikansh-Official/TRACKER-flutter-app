# Normal-user UX redesign

## Finding

The original home experience exposed seven equal destinations, several toolbar
actions, a floating icon with no visible label, four dashboard metrics, and a
large editorial hero before a person could act. The app was capable, but it
asked a new user to learn the product's internal structure before completing a
simple task.

## Design changes implemented

1. **Today is the default home.** A task app should first answer “what should I
   do now?”, not present a dashboard of every possible tool.
2. **Four persistent destinations:** Today, Plan, Calendar, and More. Android
   guidance recommends three to five primary navigation destinations; the
   previous seven-item dock made labels and targets crowded.
3. **More is a labelled sheet, not a hidden overflow maze.** Overview,
   Routines, Mood, Insights, and Reminders remain one tap away with plain
   descriptions.
4. **One obvious primary action:** the floating button now says **Add task**.
   The full task/event editor opens only after that decision.
5. **Calmer page headings:** smaller titles, slightly more breathing room, and
   decorative orbit animation off by default. The visual identity remains, but
   the day’s content appears sooner.
6. **Progressive task capture:** Quick Capture initially asks only for task or
   event, title, optional details, and date. Repetition, time, reminders,
   priority, estimates, and checklists appear after **More details**. Existing
   item editing keeps those saved details visible.
7. **Safe back behaviour:** Back returns to Today, the app’s decision home.

## Principles used

- **Hick's Law:** more and more-complex choices increase decision time. Keep
  the always-visible choices to the actions used most often, then reveal
  specialised tools when needed.
- **Fitts's Law and Android accessibility:** touch targets need clear spacing
  and at least 48dp of interactive area. Fewer dock items and a labelled FAB
  are easier to acquire reliably.
- **Progressive disclosure:** advanced planning, reflection, routine, and
  insight tools are preserved but do not block a first task capture.
- **Jakob's Law:** familiar Android patterns—bottom navigation for sections,
  an extended FAB for creation, and a bottom sheet for secondary tools—reduce
  relearning.

## What remains intentionally available

No data model or feature was deleted. The Plan screen still contains focus,
goals, and weekly review; More still exposes routines, mood, insights,
overview, and reminders. This is a navigation simplification, not a reduction
of user-owned data or capabilities.
