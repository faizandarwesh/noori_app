abstract final class Routes {
  static const splash = '/';
  static const language = '/language';
  static const home = '/home';
  static const settings = '/settings';
  static const jar = '/jar';
  static const lantern = '/lantern';
  static const wardrobe = '/lantern/wardrobe';
  static const wordGame = '/lantern/words';
  static const goodnight = '/goodnight';
  static const demo = '/demo';

  static const storyPattern = '/story/:id';
  static const quizPattern = '/story/:id/quiz';
  static const rewardPattern = '/story/:id/reward';
  static String story(String id) => '/story/$id';
  static String quiz(String id) => '/story/$id/quiz';
  static String reward(String id) => '/story/$id/reward';
}
