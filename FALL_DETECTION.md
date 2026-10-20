# Fall detection — design and validated parameters

This document records *why* the Smart Sentinel is tuned the way it is. Every parameter in
`lib/logic/activity_profile.dart` and every constant in the sensor listener was either validated
empirically on real devices (Pixel 7a and Pixel 8 running GrapheneOS) or derived from the published
literature. **Do not change a parameter without re-running the three-test protocol below and updating this
file.**

The goal is honesty about what an offline, smartphone-only fall detector can and cannot do. Lab-trained
algorithms lose 30–50 % of their sensitivity on real-world falls (Palmerini & Klenk, *Measurement*, 2024;
Bagalà et al., *PLOS ONE*, 2012). We therefore target **70–85 % real-world sensitivity**, never the 95 %+
that lab papers claim, and we lean on the user's 30 s cancel window rather than on a perfect classifier.

## The two-stage detector

The sentinel never sends an SOS straight from an impact. It runs two independent paths:

1. **Yellow observation.** An impact above the profile's `yellowThreshold` (user-acceleration, gravity
   removed; resting ≈ 1.0 G) opens an observation window of `observationSeconds`. If the person resumes
   rhythmic movement (walking) within the window, the sentinel returns to green. If the window elapses with
   no rhythm, it fires the alarm. An impact is only trusted when corroborated by the raw accelerometer
   stream — the linear-acceleration stream alone fabricates phantom impacts during tumbles and free-fall.
2. **Orange-direct.** An impact above `orangeThreshold` is treated as catastrophic and fires the alarm
   immediately, skipping the observation window. The 30 s pre-alert on the alarm screen is still the user's
   last chance to cancel. Set `orangeThreshold` to 0 to disable this path.

Firing the alarm only arms a 30 s pre-alert; the SOS SMS is sent only if the user does not cancel.

## The rhythm detector (`_isRhythmicMovement`)

Walking is what tells the sentinel a person is fine after a stumble. It is detected from the **horizontal
plane only** (`sqrt(effX² + effY²)`), not the full acceleration magnitude. Reason: on the Pixel 8 the
gravity-bias EMA filter distorts the vertical axis under real motion and inflates the variance; the
horizontal plane also matches how a phone in a pocket actually registers gait (lateral sway plus
fore/aft), since the vertical step is damped by fabric.

Acceptance criteria, over a ~2 s window of real samples (`measuredHz × 2`):

- **≥ 4 crossings** of a 1.12 baseline (above hand-tremor noise ≈ 1.05; a real step peaks clearly higher).
  When the window mean is already elevated (> 1.5, i.e. running), crossings are recomputed over the moving
  mean instead of the fixed 1.12 baseline — an adaptive detector for sports where the gait peaks are
  themselves large.
- **Frequency ≥ 1.0 Hz** — slow walking under load is ~1–1.3 Hz; a swinging backpack or wind-driven object
  is typically below 1 Hz.
- **Coefficient of variation of inter-crossing intervals in [0.05, `cvUpperBound`]**. Below 0.05 is *too*
  regular (a mechanical pendulum). The upper bound is profile-driven.

Cancellation of a yellow state requires **3 consecutive** positive checks (≈ 6 s of sustained gait); a
single failed check resets the streak. When returning to green, the sample buffer **must** be cleared —
stale buffer data otherwise makes every subsequent impact look like a false positive.

### Why the CV upper bound is so high

The literature cites CV 0.05–0.40 for walking, but that is for wearables strapped to the trunk. A phone in
a pocket shows a **median CV ≈ 1.1, range 0.81–1.71** across walking and stairs: the fabric damps each step
and adds secondary micro-impacts, giving a multimodal (but still regular) distribution of intervals. A cap
of 1.30 (1.50 for running/trail) cancels real walking while still rejecting pure random vibration (> 1.5).

## Per-profile parameters

Automatic activity classification is not viable without a continuous heart-rate signal, which a phone does
not have — so the profile is a manual selector, which is the honest answer. Values as shipped:

| Profile | Yellow | Orange | Settling | Observation | CV cap | Impact | GPS interval | GPS dist. |
|---|---|---|---|---|---|---|---|---|
| Trekking / Hiking | 6 G | 10 G | 5 s | 60 s | 1.30 | on | 30 s | 30 m |
| Road running | 10 G | 14 G | 5 s | 60 s | 1.50 | on | 5 s | 10 m |
| Trail / MTB | 8 G | 13 G | 5 s | 60 s | 1.50 | on | 5 s | 10 m |
| Mountaineering | 6 G | 10 G | 5 s | 90 s | 1.30 | on | 30 s | 30 m |
| Paragliding | — | — | — | — | — | **off** | 2 s | 5 m |
| Kayak / Watersports | — | — | — | — | — | **off** | 15 s | 20 m |
| Horse riding | — | — | — | — | — | **off** | 15 s | 20 m |
| Professional / Rescue | 6 G | 10 G | 5 s | 120 s | 1.30 | on | 5 s | 10 m |

Notes:

- **Running** was calibrated from P8 logs: a 9.75 G foot-strike impact produced 0 crossings over 27 yellow
  checks (→ false alarm) at the trekking baseline. The fix was a higher yellow threshold (so gait peaks do
  not enter yellow) plus the adaptive moving-mean cadence detector described above.
- **Orange-direct** was calibrated on the Pixel 8: 12 G required an implausibly hard blow; 10 G is reached
  cleanly by a firm knock against a chair arm without injury. Trail/MTB and running sit higher because the
  base vibration of the activity is higher. Known trade-off: a phone dropped onto concrete can exceed 10 G
  and trip the alarm screen; the user cancels with the 2 s hold within 30 s. Accepted.
- **Impact detection off** (paragliding, kayak, horse riding) leaves the user protected by the Inactivity
  Monitor and manual SOS only. Horse cadence (trot ≈ 1.5 Hz, canter 2–3 Hz) interferes with the human-walk
  detector and there is no field data for phone-in-pocket while riding; revisit when such data exists.

## Device-specific findings

- **Sample rate must be measured at runtime, not assumed.** With `SensorInterval.gameInterval` the Pixel 7a
  delivers ≈ 58.8 Hz and the Pixel 8 ≈ 49.8 Hz — not the nominal 50 Hz. Hard-coding 50 Hz biased the Pixel
  7a frequency calculation by ~18 %. The measured rate feeds the cadence frequency calculation.
- **Pixel 8 stuck Z axis.** The device reports a near-constant `z ≈ 197 m/s²` (≈ 20 G) at rest. The gravity
  EMA filter (α = 0.998, time constant ≈ 5 s) absorbs it as bias and subtracts it. This filter must **not**
  feed the cadence detector: under real vertical motion the EMA damps asymmetrically and inflates the CV.
  Hence the horizontal-plane-only cadence detector, which resolves the Pixel 8 without affecting the Pixel
  7a. Both devices then cancel a yellow in 10–18 s during real walking.

## Smart Beacon (post-SOS rescue aid)

Not a fall-detection algorithm. After the SOS is sent, the background service watches the user's position
and sends a follow-up SMS if they move away from the reference point, to help rescuers who may arrive hours
later. Constants (`lib/services/background_service.dart`):

- Distance threshold: **300 m** from the last reference point.
- Minimum interval between updates: **5 min** (300 s).
- Maximum updates: **20**.
- Total window: **4 h** (14 400 s), covering a typical 2–4 h rescue arrival.
- Stationary battery cost is zero (no SMS; GPS uses the active profile's passive stream). Stopped manually
  with "Restart system".

## Accepted limitations

- Rolling falls with secondary impacts: the settling window and cadence-CV help but do not solve this 100 %.
- A backpack swinging, or wind moving an object: cadence-CV rejects most, some edge cases remain.
- A person unconscious with shallow breathing is indistinguishable from a still inanimate object. Accepted.
- Mid-session activity change (e.g. kayak → walking) is not handled without continuous heart rate.

## Reference implementations (FOSS)

- **BeSafeBox** — <https://github.com/Foxpace/BeSafeBox_Android_app> — Random Forest, reported 90.5 % recall
  / 1.53 % false-positive rate over 300 h of real-life data. The strongest FOSS reference.
- **SINTEF project_gravity** — <https://github.com/SINTEF-SIT/project_gravity> — Apache-2.0; a foreground-
  service architecture close to ours.
- **altermarkive/experimental-fall-detector** — a clean implementation of Kangas 2008.

## Literature

- Palmerini & Klenk et al., cross-dataset evaluation, *Measurement* (2024).
- Bagalà et al., "Evaluation of accelerometer-based fall detection algorithms on real-world falls", *PLOS
  ONE* (2012).
- Musci et al., online fall detection with recurrent networks, *Sensors* 21/13/4335 (2021) — canonical
  pre-impact / impact / post-impact segmentation with 3.5–3.75 s windows.
- Casilari et al., review of smartphone-based fall detection, PMC10255727 (2023).
- Bourke et al., threshold-based detection (2007).

## Three-test validation protocol

Any parameter change must pass all three before merging, with the sentinel log pulled from the device
(`adb run-as … cat app_flutter/sentinel.log`):

1. Impact + walking, phone in hand.
2. Impact + walking, phone in pocket.
3. Impact + phone left on a table (no recovery → must fire).
