# Noori: Urdu Kids Stories

A bilingual (English + Urdu) cartoon story app for children aged 3–8.
Fully offline. The product spec is in `CLAUDE.md`.

- **Voice recordings:** where each audio file goes, how to record, and how
  to align the karaoke: [assets/audio/README.md](assets/audio/README.md)
- **Writing stories:** the story JSON format: [docs/story_schema.md](docs/story_schema.md)
- **Ideas for next versions:** [docs/improvement_ideas.md](docs/improvement_ideas.md)
- **Sound effects, music and ambience** are generated:
  `dart run tool/gen_audio.dart`

```
flutter test       # content checks + widget tests
flutter analyze
```
