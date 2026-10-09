# Noori — Bilingual Kids Story App (MVP)

You are a senior Flutter developer and kids-UX designer building **Noori (نوری)**, a bilingual (English + Urdu) story app for children aged 3–8. The Play Store title is **"Noori: Urdu Kids Stories"**. The app and the mascot share the name Noori. Purpose: **learning, education, engagement**. The scope is MVP, but UX quality is NOT MVP: every screen must feel alive, playful, and polished.

---

## 0. v1.1 Changes from Child Testing (OVERRIDES any conflicting section below)

### 0.1 Language Screen: playful, zero extra taps
- Remove all buttons. Noori sits on a branch holding two glowing lanterns: one shows "A", the other shows "ا".
- Lanterns sway gently. Fireflies orbit them. Each lantern softly pulses in turn with a short voice sample ("Let's read!" / "Chalo parhein!").
- On tap: the chosen lantern bursts into fireflies, the swarm flies toward the camera, and the screen transitions straight to Home. **No confirm button.**
- Language can be changed later only in Settings (behind the parent gate).

### 0.2 Home: stories only, the center of attraction
- **Remove the map and all locked zones from Home.** Locked/coming-soon content does not appear anywhere in the child UI.
- Home = a full-screen **3D story carousel**: one big story card at a time, neighbours peeking at the sides, scaled down and tilted.
- Each card is a living mini-scene, not a static image: characters idle-animate, leaves sway, the background parallaxes as the card is swiped.
- The active card floats (slow bob) and has a soft glow; swipe has spring physics and a whoosh sound.
- Noori sits in a corner, reacting to swipes (head follows the card direction). No speech on this screen except one line on first-ever visit.
- Tap a card: hero transition, the card expands to full screen and becomes the story's first scene.
- Completed stories show a small golden firefly badge on their card. Nothing else clutters the screen.
- Only one tiny icon at the top: a gear for Settings (parent gate first). Word Jar, Parent Corner, Bedtime toggle, and language all move into Settings.
- Background: rich animated gradient sky (dawn colours shifting slowly), drifting clouds, and floating fireflies.

### 0.3 Cinematic Auto-Play Story Mode (default)
- Stories play like a cartoon. **No tapping is needed to move forward.**
- Each page is a scene. When narration of a page ends, wait ~1.2s, then auto-transition to the next scene with a cinematic crossfade or camera move (no page curl).
- During each scene, apply a slow Ken Burns camera effect (pan + zoom, 6–10s), and animate characters (bob, blink, walk-in, small actions tied to the text).
- Karaoke highlighting continues on a minimal subtitle strip at the bottom with a soft gradient behind it.
- Ambient soundscape per scene (birds, river, wind) under the narration, plus soft background music, both ducked while narration plays.
- Tap anywhere: pause, with a big play button. Swipe left/right: optional manual skip. Language Flip stays as a small corner button.
- Auto-play pauses only at the Choice Moment. After the choice, it continues automatically.
- Quiz and reward run after the story ends, then return to Home.

### 0.4 Noori speaks much less
- Noori speaks only at: first launch (one greeting), the Choice Moment, the quiz, and the reward.
- Remove per-screen instructions and repeated hints. The idle pointing hand stays visual-only (no voice) and only on the quiz and choice screens, after 8 seconds.
- During stories, Noori is completely silent.

### 0.5 Narration: human-quality voice
- **Remove `flutter_tts` from story narration.** Narration comes only from pre-recorded or pre-generated audio files bundled with the app.
- Each page has one audio file: `assets/audio/stories/<story_id>/<lang>/page_<n>.mp3`.
- Each page JSON has a `words` array with `start`/`end` timestamps (ms) for karaoke, generated offline from the audio with Whisper word-level timestamps.
- Write a script `tools/align_audio.py` that runs Whisper on each audio file and writes the word timings into the story JSON.
- `flutter_tts` may remain only as a fallback for tap-a-word in the Word Jar.

---

## 1. Product Scope (MVP)
- One unlocked zone: **Jungle** with **5 original stories**.
- Four locked zones on the map: Samandar (Sea), Gaon (Village), Aasman (Sky), Space. They are visible but locked.
- Core features in every story:
  - **Karaoke read-along**: the word currently being narrated is highlighted.
  - **Language Flip**: switch the current page between English and Urdu instantly.
  - **Tap-a-word**: speaks the word and shows its meaning in the other language.
  - **One Choice Moment** per story: the child picks A/B, and the next page reflects the choice.
  - **3-question picture quiz** at the end.
  - **Roshni (light) reward system**: each correct answer earns one firefly light.
- No login, no backend, no network calls, no paid APIs. Fully offline.

## 2. Mascot: "Noori" the Owl
- Original character with no resemblance to any existing brand or cartoon owl. Round body, big eyes, small scarf, soft teal/cream palette.
- Build Noori in-code (layered SVG or CustomPainter) so every part animates separately: eyes blink, wings flap, body bobs, head tilts.
- Noori has states: `idle`, `talking`, `happy` (jump + wings up), `thinking`, `sleepy` (bedtime), `pointing`.
- Noori appears on every screen and **guides the child at every step** (see section 4).
- Name note: never call her "ullu" in any text or audio. In Urdu that word is an insult. Always use "Noori".
- Fireflies (jugnu) are the collectible lights. Noori collects them in her lantern.
- Use "Noori" consistently for the app name, package name (`com.<yourname>.noori`), launcher label, and splash. Do not use "Jugnu" as the app name anywhere.

## 3. Screens
- **Splash**: night sky, fireflies gather to spell "Noori" (then "نوری"), Noori flies in and waves. About 2.5 seconds, tap to skip.
- **Language Pick** (first launch only): two big bouncing cards, "English" and "اردو", each with a voice sample on tap.
- **Story Map (Home)**:
  - Illustrated jungle island with parallax layers (sky, far trees, near trees, foreground leaves) that drift slowly.
  - 5 story stops along a winding dotted path. Completed stops glow gold and show stars earned.
  - Locked zones are shown faded with a padlock. On tap: the lock shakes, a chain rattle sound plays, and Noori says "Pehle jungle ki kahaniyan poori karo!" / "Finish the jungle stories first!"
  - Top bar: Noori's lantern with a firefly count that bounces when it changes, a Bedtime toggle, and a parent gate icon.
- **Story Reader**:
  - Full-screen illustration with parallax layers. Text sits in a rounded card at the bottom.
  - Page-curl transition between pages.
  - Big Language Flip button (🔁). On flip, the text card does a 3D flip animation.
  - Urdu text is RTL, in Noto Nastaliq Urdu, with generous line height.
  - Controls: play/pause, replay page, next/back arrows. Each control is at least 72dp and bounces on press.
- **Choice Moment**: two large illustrated choice cards that wiggle gently. Noori says "Tum kya karoge?" / "What would you do?"
- **Quiz**: 3 questions. Each question has 3 picture options. Correct answer: the card pops, confetti plays, a firefly flies into the lantern. Wrong answer: the card shakes softly, Noori says "Phir se koshish karo!" / "Try again!" Never use harsh sounds, red X marks, or failure screens.
- **Reward Screen**: fireflies swirl into Noori's lantern, stars are awarded (1–3), then a new word card is collected into the **Word Jar**.
- **Word Jar**: a glass jar of collected word cards. Tap a card to hear the word in both languages.
- **Parent Corner** (behind the parent gate): stories completed, words learned, total listening time, language setting, sound toggle.
- **Parent gate**: a simple math question with written-out numbers, such as "Seven plus five?" Required before settings or any outbound link.

## 4. Child Guidance (every step)
- Every screen starts with Noori speaking one short instruction (voice + animated speech bubble), for example "Kahani par tap karo!" / "Tap a story to begin!"
- After 5 seconds of no interaction, show a pulsing animated pointing hand on the next expected action, and Noori repeats the hint.
- Instructions are voice-first. Assume the child cannot read. Text in bubbles is secondary.
- All guidance lines live in `assets/content/guide_lines.json` with `en` and `ur` keys.

## 5. Animation & Feel (non-negotiable)
- Use `flutter_animate` for most micro-animations and `lottie` for confetti, sparkles, and firefly swirls.
- **Every tappable element**: squash-and-stretch press (scale 0.9 → 1.08 → 1.0, elastic curve), plus a tap sound and light haptic.
- **Idle life on every screen**: floating fireflies, swaying leaves, Noori blinking every 3–5 seconds, and a gentle breathing scale on primary buttons.
- **Staggered entrances**: elements pop in one after another with 60–80ms offsets, never all at once.
- Rewards feel big: confetti, a firefly trail animating into the lantern, the counter bumping up, a sparkle sound.
- Target 60fps on mid-range Android. Use `RepaintBoundary` around heavy animated layers and dispose all controllers.
- Keep background music soft (loopable, toggleable) and duck it during narration.

## 6. Visual Design System
- **Day theme**: peach `#FFD6BA`, mint `#B8F2E6`, sky `#AED9E0`, accent sunshine `#FFB703`, accent coral `#FB8500`.
- **Bedtime theme**: deep navy `#1B1F3B`, indigo `#2E3267`, glow gold `#FFD166`. Slower narration, sleep timer (5/10/15 min), and Noori in `sleepy` state.
- **Fonts**: Fredoka (English), Noto Nastaliq Urdu (Urdu). Minimum body size 22sp for English, 26sp for Urdu.
- Rounded corners 24–32dp, soft shadows, "puffy" 3D buttons (bottom shadow darker than fill).
- Illustrations: original flat-vector SVG in one consistent style (simple shapes, soft gradients, no outlines thicker than 3px). Characters are animals: rabbit, turtle, elephant, parrot, monkey. No copyrighted characters.
- Put all design tokens in `lib/core/theme/`. Never hardcode colors or sizes in widgets.

## 7. Content (write it yourself)
- Write 5 **original** short stories for ages 3–8. Each has 6–8 pages with 1–3 short sentences per page.
- Each story teaches one value: sharing, honesty, kindness, patience, courage.
- Urdu must be natural, simple spoken Urdu for children, not a literal translation of the English.
- Each story includes: title (en/ur), pages (en/ur text + illustration id), one choice moment with two branches, 3 quiz questions with picture options, and 3 vocabulary words with meanings in both languages.
- Store each story as JSON in `assets/content/stories/`. The schema must allow new zones and stories without code changes.
- Word timings for karaoke:
  - English: use `flutter_tts` progress callbacks for word boundaries.
  - Urdu: support an optional recorded audio file per page with a word-timestamp array in JSON. If there's no recording, fall back to TTS and highlight by estimated timing.

## 8. Tech Stack & Architecture
- Flutter (latest stable), Dart null-safety, Android first (iOS-compatible code).
- State: Riverpod. Routing: go_router. Local storage: Hive (progress, fireflies, word jar, settings).
- Packages: `flutter_animate`, `lottie`, `flutter_svg`, `flutter_tts`, `audioplayers`, `confetti`, `hive_flutter`, `google_fonts` (bundle fonts offline).
- Structure: feature-first under `lib/features/` (map, reader, quiz, reward, word_jar, parent), with shared code in `lib/core/` (theme, audio, widgets, mascot).
- Build a reusable `BouncyButton`, `NooriMascot`, `SpeechBubble`, `FireflyLayer`, `ParallaxScene`, and `GuideHint` first. Every screen must use them.
- One `AudioService` manages music, SFX, and narration with ducking.

## 9. Play Store & Kids Safety
- Follow the Google Play **Families Policy**.
- No ads, no analytics SDKs, no data collection, no internet permission.
- Every outbound link or settings change goes behind the parent gate.
- Include a simple in-app privacy note stating that no data leaves the device.

## 10. Build Order
- Step 1: Theme, core widgets, Noori mascot with all states. Show a demo screen before moving on.
- Step 2: Story Map with parallax, locked zones, and guidance.
- Step 3: Story JSON schema + first story + reader (karaoke, flip, tap-a-word, page curl).
- Step 4: Choice moment, quiz, reward, firefly system, Word Jar.
- Step 5: Remaining 4 stories, bedtime mode, parent corner, parent gate.
- Step 6: Polish pass: check every screen for idle animation, press feedback, voice guidance, and 60fps.
- After each step, run the app, fix all analyzer warnings, and summarize what was built in 3–5 lines.

## 11. Definition of Done
- A child who cannot read can open the app, pick a story, finish it, answer the quiz, and see the reward using only Noori's voice guidance.
- No screen is ever static. Something always moves gently.
- English and Urdu both work fully, including RTL layout.
- Works fully offline with zero analyzer warnings.