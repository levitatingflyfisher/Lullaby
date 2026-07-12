# Reference: feature status

What is shipped, partial, or not built — as of **v1.0.0**. Cross-check against
[VISION.md § Honest scorecard](../VISION.md#honest-scorecard--built-vs-aspirational)
and [limitations.md](../limitations.md). Remember the [grain-of-salt](../../AGENTS.md#take-the-code-as-current-state-not-gospel):
this reflects the code as read, verified by the test suite where noted.

| Area | Status | Notes |
|---|---|---|
| **Feeding tracker** | ✅ Shipped | breast/bottle/solid, side, ml & oz, live timer; tested |
| **Sleep tracker** | ✅ Shipped | nap/night, start-stop timer, location; tested |
| **Diaper tracker** | ✅ Shipped | wet/dirty/both/dry, colour; tested |
| **Growth + WHO curves** | ✅ Shipped | weight/height/head vs boys/girls percentiles; tested |
| **Medicine log** | ✅ Shipped | name, dose, unit, time; tested |
| **Vaccine history** | ✅ Shipped | name, dose #, scheduled/administered, provider; tested |
| **Dashboard** | ✅ Shipped | quick-log buttons, active-timer card, daily summary strip |
| **Calendar** | ✅ Shipped | monthly view with per-day event markers |
| **Timeline** | ✅ Shipped | reverse-chronological feed with filter chips |
| **Statistics** | ✅ Shipped | feeding-trend, sleep-pattern, diaper-frequency charts; 7/14/30-day windows |
| **Doctor summary** | ✅ Shipped | at-a-glance summary for appointments |
| **PDF export** | ✅ Shipped | doctor summary as PDF via share sheet |
| **CSV export** | ✅ Shipped | summary & raw CSV, **formula-injection-safe** (tested) |
| **Multiple babies** | ✅ Shipped | profiles + switcher; one active at a time |
| **Home-screen widget** | ✅ Shipped | baby name + last feed/sleep/diaper + active timer |
| **Dark mode / Material 3** | ✅ Shipped | system + manual; dynamic colour on Android 12+ |
| **Encrypted backup / restore** | ✅ Shipped | app-side flow + OHBK format real & tested, real audited crypto (`sanctuary_auth_core`, sibling path dep); pre-rewire (CI-stub-era) exports are a known, documented incompatibility — see [limitations.md](../limitations.md#known-incompatibility-pre-rewire-stub-era-backups) |
| **Seed-phrase recovery** | ✅ Shipped | generate/confirm/derive-key flow on the real `sanctuary_auth_core` module |
| **Multi-device sync** | ❌ Not shipped | no server; sharing = carry an encrypted backup |
| **"Named"/account tier** | ❌ Not shipped | `AuthTier.named` exists in the enum; only `ghost` runs |
| **Reminders / notifications** | ❌ Not built | no scheduled reminders |
| **App-store release** | ❌ Not done | `applicationId` still `com.example.lullaby`; release CI omitted |
| **Screenshots** | ❌ Pending | README says "coming soon" |

## Platforms

| Target | Buildable | CI-verified |
|---|---|---|
| Android | ✅ | analyze + test on Linux (not device) |
| iOS | ✅ | ❌ |
| Linux desktop | ✅ | ❌ |
| Web | ✅ (WasmDatabase) | ❌ |

CI (`.github/workflows/ci.yml`) runs `flutter analyze` + `flutter test` on Linux
for every push and PR. Platform-specific builds are not exercised by CI.
