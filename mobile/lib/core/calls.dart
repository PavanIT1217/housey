// What the caller shows and says for each number (as in js/core/calls.js).

/// Traditional calls, indexed by number (index 0 is unused).
const traditionalCalls = <String>[
  '',
  "Kelly's eye",
  'One little duck',
  'Cup of tea',
  'Knock at the door',
  'Man alive',
  'Half a dozen',
  'Lucky seven',
  'Garden gate',
  "Doctor's orders",
  'Cock and hen',
  'Legs eleven',
  'One dozen',
  'Unlucky for some',
  "Valentine's day",
  'Young and keen',
  'Sweet sixteen',
  'Dancing queen',
  'Coming of age',
  'Goodbye teens',
  'One score',
  'Key of the door',
  'Two little ducks',
  'Thee and me',
  'Two dozen',
  'Duck and dive',
  'Pick and mix',
  'Gateway to heaven',
  'Overweight',
  'Rise and shine',
  'Dirty Gertie',
  'Get up and run',
  'Buckle my shoe',
  'All the threes',
  'Ask for more',
  'Jump and jive',
  'Three dozen',
  'More than eleven',
  'Christmas cake',
  'Climb the steps',
  'Naughty forty',
  'Time for fun',
  'Winnie the Pooh',
  'Down on your knees',
  'Droopy drawers',
  'Halfway there',
  'Up to tricks',
  'Four and seven',
  'Four dozen',
  'P.C.',
  'Half a century',
  'Tweak of the thumb',
  'Danny La Rue',
  'Stuck in the tree',
  'Clean the floor',
  'Snakes alive',
  'Was she worth it',
  'Heinz varieties',
  'Make them wait',
  'Brighton line',
  'Five dozen',
  "Baker's bun",
  'Turn the screw',
  'Tickle me',
  'Red raw',
  'Old age pension',
  'Clickety click',
  'Stairway to heaven',
  'Saving grace',
  'Either way up',
  'Three score and ten',
  'Bang on the drum',
  'Six dozen',
  'Queen bee',
  'Candy store',
  'Strive and strive',
  'Trombones',
  'Sunset strip',
  "Heaven's gate",
  'One more time',
  'Eight and blank',
  'Stop and run',
  'Straight on through',
  'Time for tea',
  'Seven dozen',
  'Staying alive',
  'Between the sticks',
  'Torquay in Devon',
  'Two fat ladies',
  'Nearly there',
  'Top of the shop',
];

const _digits = ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine'];
String _digitsOf(int n) => '${_digits[n ~/ 10]} and ${_digits[n % 10]}';
String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);

/// Ways of calling a number. [number] is the default: just the number, no phrase.
enum CallStyle {
  number('Number only', '“Number 22”'),
  digits('Digits too', '“Two and two, 22”'),
  traditional('Traditional', '“Two little ducks… 22”');

  const CallStyle(this.label, this.example);
  final String label;
  final String example;

  static CallStyle byName(String? name) => values.firstWhere((s) => s.name == name, orElse: () => CallStyle.number);
}

/// The words to show on screen and to speak for a number.
typedef Call = ({String display, String speech});

Call describeCall(int n, [CallStyle style = CallStyle.number]) => switch (style) {
  CallStyle.number => (display: 'Number $n', speech: 'Number $n.'),
  CallStyle.digits =>
    n < 10
        ? (display: 'Single number $n', speech: 'Single number, $n.')
        : (display: '${_capitalize(_digitsOf(n))}, $n', speech: '${_digitsOf(n)}, $n.'),
  CallStyle.traditional => (
    display: traditionalCalls[n],
    speech: n < 10 ? '${traditionalCalls[n]}. Number $n.' : '${traditionalCalls[n]}. ${_digitsOf(n)}, $n.',
  ),
};
