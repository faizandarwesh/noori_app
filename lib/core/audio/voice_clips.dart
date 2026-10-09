import '../i18n/app_lang.dart';

/// Where every recorded voice clip lives. Paths are relative to `assets/`
/// (the prefix audioplayers adds). A clip that isn't bundled yet is simply
/// skipped: Noori's line shows as a bubble only and story pages play as a
/// silent read-along, so the app works while recordings are in progress.
///
/// `dart run tool/align_audio.dart --check` lists every clip still missing;
/// assets/audio/README.md explains where each recording goes.
abstract final class VoiceClips {
  /// Noori's guide lines, from guide_lines.json.
  static String guide(String key, AppLang lang) =>
      'audio/guide/${lang.name}/$key.mp3';

  static String _story(String storyId, AppLang lang) =>
      'audio/stories/$storyId/${lang.name}';

  /// One narration file per page: page id `p5_share` → `page_5_share.mp3`.
  /// A branch page named `choice_a` keeps its name (`choice_a.mp3`).
  static String page(String storyId, String pageId, AppLang lang) =>
      pageId.startsWith('choice_')
      ? '${_story(storyId, lang)}/$pageId.mp3'
      : '${_story(storyId, lang)}/page_${pageNumber(pageId)}.mp3';

  /// The Choice Moment's question, named after its node id.
  static String choice(String storyId, String nodeId, AppLang lang) =>
      '${_story(storyId, lang)}/$nodeId.mp3';

  /// Quiz question [index] (0-based) → `quiz_1.mp3` …
  static String quiz(String storyId, int index, AppLang lang) =>
      '${_story(storyId, lang)}/quiz_${index + 1}.mp3';

  /// A character saying hello when tapped in a scene, e.g. `name_rabbit.mp3`.
  static String name(String storyId, String characterId, AppLang lang) =>
      '${_story(storyId, lang)}/name_$characterId.mp3';

  /// A quiz "Where is …?" question for one character, e.g. `find_rabbit.mp3`.
  static String find(String storyId, String characterId, AppLang lang) =>
      '${_story(storyId, lang)}/find_$characterId.mp3';

  /// A glossary word on its own, for the Word Jar and tap-a-word.
  static String word(String storyId, String wordId, AppLang lang) =>
      '${_story(storyId, lang)}/word_$wordId.mp3';

  static String pageNumber(String pageId) =>
      pageId.startsWith('p') ? pageId.substring(1) : pageId;
}
