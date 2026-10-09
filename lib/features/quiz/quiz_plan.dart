import '../../core/content/story.dart';

/// One question in a quiz round.
sealed class QuizItem {
  const QuizItem();
}

/// Tap the right one of three pictures.
class PickItem extends QuizItem {
  const PickItem(this.question, this.index);

  final QuizQuestion question;

  /// Position in the story's quiz list (names its recording, `quiz_<n>.mp3`).
  final int index;
}

/// Drag a picture onto the right one of three.
class DragItem extends QuizItem {
  const DragItem(this.question, this.index);

  final QuizQuestion question;
  final int index;
}

/// Tap three scenes in story order: first, next, last.
class OrderItem extends QuizItem {
  const OrderItem(this.pages, this.shown);

  /// The scenes in story order.
  final List<StoryPage> pages;

  /// How they are laid out: indexes into [pages], never already in order.
  final List<int> shown;
}

/// Find a character hiding in a scene and tap them.
class FindItem extends QuizItem {
  const FindItem(this.page, this.castIndex, this.characterId);

  final StoryPage page;
  final int castIndex;
  final String characterId;
}

const _layouts = [
  [1, 2, 0],
  [2, 0, 1],
  [1, 0, 2],
  [0, 2, 1],
  [2, 1, 0],
];

/// The three questions for [story] on its [play]-th quiz (0 = first time).
///
/// Two picture questions plus one special question (drag, order or find),
/// rotating with every replay so the same story stays fresh.
List<QuizItem> planQuiz(Story story, int play) {
  final picks = [
    for (final (i, q) in story.quiz.indexed)
      if (q.kind == QuizKind.pick) PickItem(q, i),
  ];
  final specials = <QuizItem>[
    for (final (i, q) in story.quiz.indexed)
      if (q.kind == QuizKind.drag) DragItem(q, i),
    ?_order(story, play),
    ?_find(story, play),
  ];
  if (picks.isEmpty) return specials.take(3).toList();
  PickItem pick(int k) => picks[(play + k) % picks.length];
  if (specials.isEmpty) return [pick(0), pick(1), pick(2)];
  return [pick(0), specials[play % specials.length], pick(1)];
}

OrderItem? _order(Story story, int play) {
  final pages = story.pathPages;
  if (pages.length < 3) return null;
  return OrderItem([
    pages.first,
    pages[pages.length ~/ 2],
    pages.last,
  ], _layouts[play % _layouts.length]);
}

/// A named character in a page with company, so there's something to find.
FindItem? _find(Story story, int play) {
  final spots = [
    for (final page in story.pathPages)
      if (page.cast.length >= 2)
        for (final (i, m) in page.cast.indexed)
          if (m.art.isCharacter && story.characters.containsKey(m.art.id))
            FindItem(page, i, m.art.id),
  ];
  return spots.isEmpty ? null : spots[play % spots.length];
}
