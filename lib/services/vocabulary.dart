import '../data/afinn_lexicon.dart';
import '../data/emotion_lexicon.dart';
import '../data/mental_health_lexicon.dart';
import '../data/slang_lexicon.dart';

/// Words the app recognises, used to tell real language from noise and to
/// repair stretched spellings ("yesss" -> "yes").
class Vocabulary {
  const Vocabulary._();

  static bool isKnown(String w) =>
      common.contains(w) ||
      SlangLexicon.map.containsKey(w) ||
      AfinnLexicon.words.containsKey(w) ||
      MentalHealthLexicon.domainKeywords.containsKey(w) ||
      MentalHealthLexicon.negators.contains(w) ||
      MentalHealthLexicon.intensifiers.containsKey(w) ||
      EmotionLexicon.words.containsKey(w) ||
      MentalHealthLexicon.affirmationPhrases.contains(w) ||
      MentalHealthLexicon.denialPhrases.contains(w);

  /// Everyday English words (function words plus common words in answers
  /// about feelings, sleep, work, people and routine).
  static final Set<String> common = {
    // function words
    'i', 'me', 'my', 'mine', 'myself', 'we', 'us', 'our', 'you', 'your',
    'he', 'him', 'his', 'she', 'her', 'it', 'its', 'they', 'them', 'their',
    'a', 'an', 'the', 'and', 'or', 'but', 'if', 'so', 'because', 'as',
    'of', 'to', 'in', 'on', 'at', 'by', 'for', 'with', 'about', 'from',
    'into', 'over', 'after', 'before', 'than', 'then', 'when', 'while',
    'is', 'am', 'are', 'was', 'were', 'be', 'been', 'being', 'do', 'does',
    'did', 'have', 'has', 'had', 'will', 'would', 'can', 'could', 'should',
    'may', 'might', 'must', 'this', 'that', 'these', 'those', 'there',
    'here', 'what', 'which', 'who', 'why', 'how', 'where', 'all', 'any',
    'some', 'more', 'less', 'most', 'many', 'few', 'other', 'another',
    'just', 'only', 'also', 'even', 'still', 'again', 'now', 'today',
    'yesterday', 'tomorrow', 'lately', 'recently', 'sometimes', 'often',
    'never', 'always', 'usually', 'rarely', 'ever', 'once', 'twice',
    'maybe', 'perhaps', 'probably', 'really', 'very', 'quite', 'bit',
    'little', 'lot', 'much', 'enough', 'too', 'almost', 'nearly',
    // short replies
    'ok', 'okay', 'yes', 'yeah', 'yep', 'no', 'nope', 'nah', 'idk', 'sure',
    'fine', 'well', 'hmm', 'um', 'uh', 'please', 'thanks', 'thank', 'hi',
    'hello', 'hey', 'sorry', 'not', 'dont', 'cant', 'cannot', 'wont',
    // common verbs / nouns in this domain
    'feel', 'feeling', 'felt', 'feels', 'think', 'thinking', 'thought',
    'know', 'want', 'need', 'get', 'got', 'getting', 'go', 'going', 'went',
    'come', 'came', 'make', 'made', 'take', 'took', 'keep', 'kept', 'try',
    'tried', 'trying', 'start', 'stop', 'stopped', 'find', 'found', 'see',
    'say', 'said', 'tell', 'told', 'talk', 'talking', 'help', 'let',
    'like', 'love', 'enjoy', 'miss', 'care', 'work', 'working', 'job',
    'school', 'college', 'class', 'study', 'studying', 'home', 'family',
    'friend', 'friends', 'people', 'person', 'everyone', 'someone',
    'nobody', 'nothing', 'something', 'everything', 'anything', 'day',
    'days', 'night', 'nights', 'week', 'weeks', 'month', 'months', 'year',
    'time', 'times', 'morning', 'evening', 'sleep', 'sleeping', 'slept',
    'eat', 'eating', 'food', 'energy', 'mind', 'head', 'body', 'heart',
    'life', 'thing', 'things', 'way', 'lots', 'hard', 'easy',
    'better', 'worse', 'best', 'worst', 'good', 'bad', 'ago', 'long',
    'last', 'next', 'same', 'different', 'new', 'old', 'own', 'since',
    'during', 'every', 'each', 'both', 'either', 'neither',
    'worry', 'worried', 'activities', 'interest', 'situation',
    'problem', 'problems', 'issue', 'issues', 'changes', 'change',
    'hobbies', 'hobby', 'enjoyable', 'enjoyment', 'usual', 'normal',
  };
}
