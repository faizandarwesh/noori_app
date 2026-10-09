# Noori: improvement ideas (from a child's point of view)

Suggestions for the next versions, written from the point of view of a
3–8-year-old using the app. Each one is grounded in how the app works today.
They're ordered by how much they'd matter to a child.

**Recommended order:** do #1 and #2 first (small code changes, big comfort
gain), then #4 and #5 together (a meaningful reward loop).

**Status:** #1, #2, #4, #5, #6 and #7 are done. #3 waits on the voice
recordings; #8–#11 are next.

---

## Do first: things a child would struggle with

### 1. A tap shouldn't pause the story

> **Done (2026-10-01).** Characters hop and giggle (or say their name, once
> `name_<character>.mp3` is recorded), props wiggle with a boing, and empty
> scenery sparkles. Pause is a small top-bar button or a two-finger tap.

Young children tap everything on screen, especially characters. Right now any
tap pauses the cartoon, so a 4-year-old tapping Bunty gets a frozen screen
and a big play button. That feels like they broke it.

- **Fix:** tapping a character makes it react (giggle, hop, say its name),
  and tapping a prop makes it wiggle or bounce.
- Pause only with a small pause button, or a two-finger tap.
- This turns the child's habit into fun instead of interruptions.

### 2. Swipes skip scenes too easily

> **Done (2026-10-01).** Swipe-to-skip is off by default, with a switch in
> Settings. When on, only a long swipe (over a third of the screen) skips.

Little hands drag across the screen by accident, and a single swipe skips a
whole scene.

- **Fix:** require a longer, more deliberate swipe, or have grown-ups turn
  swipe-to-skip on in Settings.
- Most children this age watch straight through anyway.

### 3. Recorded voices, including voices for the characters

This is already planned, and nothing matters more for children who can't
read (see [assets/audio/README.md](../assets/audio/README.md)).

- One more step makes it much more engaging: give each animal its own voice
  for their lines (Bunty high and bouncy, Gulu deep and slow), with a narrator
  for the rest.
- It works with the current setup, as long as each page stays one recording.

---

## Next: make them want to come back

### 4. Let children see what they've collected

> **Done (2026-10-01).** A lantern beside Noori on Home glows brighter with
> every firefly earned. Tapping Noori or the lantern opens Noori's Lantern,
> the child's own corner: the big lantern with their fireflies flying
> inside, and doors to the wardrobe and the word game.

Home is clean now, but the fireflies a child earns have disappeared from
view, so there's nothing to show for their effort.

- **Idea:** Noori's lantern in her corner glows brighter as fireflies add up.
- Tapping Noori shows the lantern filling up.
- It adds no clutter but gives a real sense of progress.

### 5. Spend fireflies on something

> **Done (2026-10-01).** Noori's wardrobe: five scarf colours (5–15
> fireflies) and four hats (5–15). Bought items go straight on, and Noori
> wears them on every screen. Spending never dims the lantern, which glows
> by everything ever earned.

Collecting is fun only if the collection is used.

- **Idea:** children unlock scarf colours or hats for Noori (10 fireflies
  each), or stickers.
- This is safe under Google Play's Families Policy because it uses only
  earned fireflies: no ads and no real money.

### 6. Give children their own Word Jar

> **Done (2026-10-01).** The word game: a word is spoken and the child taps
> its picture, five rounds for a firefly. Words from stories they've heard
> come first. Grown-ups' Word Jar stays in Settings.

The Word Jar now sits behind the parent gate, so children can't revisit
their own words.

- **Idea:** a simple word game children can open themselves, such as a
  picture with "Tap the mango!" spoken aloud.
- Settings could still hold the full list for parents.

### 7. More kinds of play in the quiz

> **Done (2026-10-01).** Each quiz is two picture questions plus one
> special that rotates every replay: drag a picture to its place (one
> written per story), put three scenes in story order, or find a character
> in a scene.

All 15 questions work the same way: tap one of three pictures.

- **Ideas:** drag the mango to the friend, put three scenes in order, find
  the hidden turtle in the scene.
- Rotating the type keeps it fresh when a child plays the same story again.

---

## Later: deeper learning and wider appeal

### 8. Use both languages together

Today the app is either English or Urdu. Since bilingual learning is the
app's goal:

- After each page, offer "hear it in the other language" (one tap, both
  recordings).
- Optionally show both subtitles, with the main language large and the other
  small.

### 9. Let the child pick an animal of their own

On first launch the child picks one (a cat, a fox, a duck).

- It then appears with Noori on Home, in the reward screen, and waving in
  the stories.
- It makes the app feel like theirs, and no names need recording.

### 10. A gentle bedtime story mode

In Bedtime mode, "Play all": stories run back to back with no quiz, and the
music and the scenes slowly fade to dark. Parents would really value this.

### 11. More stories, released regularly

Five stories is a short app for a child who replays favourites.

- The content format lets you add stories without code changes (see
  [story_schema.md](story_schema.md)).
- A "new story" glow on a card (only until it's played once) brings children
  back without manipulating them.

---

## The most valuable step of all

Watch 3–4 children play for 10 minutes, without helping. Note:

- where they tap,
- where they get stuck,
- when they stop paying attention.

The tap-to-pause problem (#1) is a prediction; real children will show you
things neither of us expects.
