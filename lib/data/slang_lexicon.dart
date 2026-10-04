/// Informal / Gen-Z spellings and what they mean in plain words.
///
/// Used by [TextUtils.normalize] so the sentiment, emotion and risk
/// analysers (which know standard words) can read how people really type.
/// An empty replacement means "filler, drop it".
class SlangLexicon {
  const SlangLexicon._();

  static const Map<String, String> map = {
    // --- yes / no / agreement ---
    'yea': 'yes', 'yeh': 'yes', 'yh': 'yes', 'yuh': 'yes', 'yup': 'yes',
    'yep': 'yes', 'ya': 'yes', 'yas': 'yes', 'yass': 'yes', 'ikr': 'yes',
    'ye': 'yes', 'definitely': 'definitely', 
    'nah': 'no', 'naw': 'no', 'nope': 'no', 'nahh': 'no',
    'k': 'ok', 'kk': 'ok',

    // --- texting shortcuts ---
    'u': 'you', 'ur': 'your', 'urself': 'yourself', 'r': 'are', 'y': 'why',
    'pls': 'please', 'plz': 'please', 'thx': 'thanks', 'ty': 'thanks',
    'bc': 'because', 'cuz': 'because', 'cos': 'because', 'coz': 'because',
    'rn': 'right now', 'tho': 'though', 'tbf': '', 'imo': '', 'imho': '',
    'idk': 'i do not know', 'idc': 'i do not care', 'idrk': 'i do not really know',
    'ngl': '', 'tbh': '', 'fr': '', 'frfr': '', 'deadass': '', 'istg': '',
    'smh': '', 'lol': '', 'lmao': '', 'lmfao': '', 'haha': '', 'hahaha': '',
    'hehe': '', 'omg': '', 'omfg': '', 'bruh': '', 'bro': '', 'dude': '',
    'fam': '', 'ugh': 'ugh', 'sksksk': '', 'lowkey': 'somewhat',
    'highkey': 'very', 'kinda': 'somewhat', 'sorta': 'somewhat',
    'hella': 'very', 'sooo': 'so',
    'gonna': 'going to', 'wanna': 'want to', 'gotta': 'have to',
    'gimme': 'give me', 'lemme': 'let me', 'dunno': 'i do not know',
    'aint': 'is not',

    // --- apostrophe-less contractions ---
    'im': 'i am', 'ive': 'i have', 'dont': 'do not', 'doesnt': 'does not',
    'didnt': 'did not', 'cant': 'cannot', 'wont': 'will not',
    'isnt': 'is not', 'arent': 'are not', 'wasnt': 'was not',
    'werent': 'were not', 'hasnt': 'has not', 'havent': 'have not',
    'hadnt': 'had not', 'wouldnt': 'would not', 'shouldnt': 'should not',
    'couldnt': 'could not',

    // --- mood slang ---
    'fml': 'my life is terrible', 'cooked': 'overwhelmed',
    'spiraling': 'anxious', 'spiralling': 'anxious',
    'drained': 'drained', 
    'shook': 'anxious', 'triggered': 'upset', 'salty': 'upset',
    'sus': 'suspicious', 'cringe': 'embarrassed', 'ghosted': 'abandoned',
    'toxic': 'toxic', 'vibes': 'mood', 'bummed': 'sad', 'bleh': 'bad',

    // --- euphemisms for suicide / self-harm (important for risk) ---
    'unalive': 'kill', 'unaliving': 'killing', 'unalived': 'killed',
    'kms': 'kill myself', 'ctb': 'commit suicide', 'sewerslide': 'suicide',
    'selfharm': 'self harm',
  };

  /// Emoji that carry a clear feeling, as plain words.
  static const Map<String, String> emoji = {
    '😢': ' sad ',
    '😞': ' sad ',
    '😔': ' sad ',
    '😥': ' sad ',
    '😿': ' sad ',
    '😡': ' angry ',
    '🤬': ' furious ',
    '😠': ' angry ',
    '😰': ' anxious ',
    '😨': ' scared ',
    '😱': ' scared ',
    '😩': ' exhausted ',
    '😫': ' exhausted ',
    '😴': ' tired ',
    '😊': ' happy ',
    '😄': ' happy ',
    '🙂': ' fine ',
    '❤️': ' ',
    '💔': ' heartbroken ',
  };
}
