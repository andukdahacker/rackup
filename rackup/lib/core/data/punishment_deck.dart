import 'dart:math';

/// Built-in punishment deck for lobby punishment submission.
///
/// A collection of fun, bar-appropriate punishments that players can use
/// as-is or as inspiration for custom punishments. Reused by Epic 4 for
/// game-phase punishment draws.
const List<String> builtInPunishments = [
  'Do your best impression of someone here',
  "Text the 3rd person in your contacts 'I love you'",
  'Speak in an accent until your next turn',
  'Let the group pick your next drink order',
  'Do 10 push-ups right now',
  'Show the last photo in your camera roll',
  'Call a friend and sing Happy Birthday to them',
  'Let someone post anything on your social media',
  'Do your best celebrity impression chosen by the group',
  'Swap an article of clothing with the person to your left',
  'Talk in the third person until your next turn',
  'Let the group go through your search history for 30 seconds',
  'Do a dramatic reading of your last sent text message',
  'Hold an ice cube in your hand until it melts',
  'Compliment every person at the table sincerely',
  'Do your best dance move right now',
  'Speak only in questions until your next turn',
  'Let the group choose a new nickname for you tonight',
  'Tell your most embarrassing story',
  'Do a plank for 30 seconds',
  'Serenade the person across from you',
  'Show the group your screen time report',
  'Eat a spoonful of something the group picks',
  'Give your phone to someone for 60 seconds',
  'Do your best animal impression chosen by the group',
  'Take a selfie with a stranger and post it',
  'Speak in a whisper until your next turn',
  'Let the person to your right draw on your arm',
  'Recite the alphabet backwards',
  'Make up a rap about the person to your left',
];

final Random _random = Random();

/// Returns a random punishment from the built-in deck.
String randomPunishment() {
  return builtInPunishments[_random.nextInt(builtInPunishments.length)];
}
