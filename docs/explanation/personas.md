# Personas

Agents drive the real Lullaby build as these people, per the fleet testing
rule. Each scenario gives a start state, plain steps, what success looks like,
and what to check. "Standard checks" means: text scale 1.3 at 360 dp width,
dark mode, airplane mode, and every error in plain words with a way forward.
Scenarios aim at the weak spots found by the September 2026 lens audit.

## Primary: Mei, a new parent on the night shift

Mei is 29, six weeks postpartum, sharing nights with their partner Jordan.
They log every feed and diaper at 3 a.m. in a dark nursery, baby on one arm,
phone in the other hand, dark mode on and brightness low.

- **Goal:** log a feed in two taps and hand the night over with the three
  daily numbers in view.
- **Context:** one-handed, half-asleep, dim screen, text scale 1.3.
- **Would quit if:** a Save silently does nothing, or typed notes vanish.

**M1. Three numbers at a glance.** Start: one baby, two feeds, one sleep,
three diapers logged today. Steps: open Home. Success: feeds, sleep and
diapers are all readable at once, no sideways scroll. Check: standard checks;
one app bar, not two.

**M2. Bottle feed from the Feed circle.** Start: Home. Steps: tap Feed; choose
Bottle in the sheet; tap Save with the amount empty; then enter 90 ml, add the
note "spit up a little", Save. Success: the form opens already on Bottle; the
empty Save is disabled or says why; the note is kept on the saved record.
Check: Notes sits above Save; the tap target includes the "Feed" label.

**M3. Breast feed after the fact.** Start: Home. Steps: log a breast feed that
already finished 20 minutes ago, left side, with a note. Success: it can be
logged without running a live timer; the note survives. Check: end time cannot
precede start time.

**M4. The Sleep circle.** Start: no sleep running. Steps: tap Sleep; lock the
phone; come back and read the circle; tap it again. Success: the control shows
it is running and says what the next tap will do. Check: long-pressing Diaper
is not the only way to its full form.

## Secondary: Jordan, preparing for the paediatrician

Jordan is 34, Mei's partner, the one who takes the baby to checkups. They
want the numbers the doctor will ask about.

- **Goal:** record today's weight and see the percentile, show a summary at
  the appointment, and set up the encrypted backup.
- **Context:** in a waiting room on patchy Wi-Fi, a few calm minutes.
- **Would quit if:** data goes in and never comes back out.

**J1. Growth and percentile.** Start: baby with birth date and two
measurements. Steps: add a weight of 4.2 kg; then find the growth chart from
inside the app. Success: a visible path reaches the chart; a percentile is
stated in words. Check: axis labels do not overlap at 1.3; offline.

**J2. Doctor summary.** Start: a week of logs. Steps: from the Baby tab or
anywhere visible, open the doctor summary and export it. Success: reachable
without typing a URL. Check: dark mode.

**J3. Medicine timing.** Start: paracetamol logged at 04:10. Steps: open
Health; try to add another dose at 06:00. Success: Health shows the last dose
and when the next is allowed. Check: page heading reads "Health".

**J4. Recovery words.** Start: Settings, no backup yet. Steps: open backup
setup; read the twelve words; tap "I've written this down". Success: words
sit on a numbered grid; something checks they were written down. Check: text
scale 1.3; delete a feed and look for Undo, not just "This cannot be undone".
