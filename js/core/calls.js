// What the caller shows and says for each number.

/** Traditional calls, indexed by number (index 0 is unused). */
export const TRADITIONAL_CALLS = Object.freeze(['',
  "Kelly's eye", 'One little duck', 'Cup of tea', 'Knock at the door', 'Man alive', 'Half a dozen', 'Lucky seven', 'Garden gate', "Doctor's orders", 'Cock and hen',
  'Legs eleven', 'One dozen', 'Unlucky for some', "Valentine's day", 'Young and keen', 'Sweet sixteen', 'Dancing queen', 'Coming of age', 'Goodbye teens', 'One score',
  'Key of the door', 'Two little ducks', 'Thee and me', 'Two dozen', 'Duck and dive', 'Pick and mix', 'Gateway to heaven', 'Overweight', 'Rise and shine', 'Dirty Gertie',
  'Get up and run', 'Buckle my shoe', 'All the threes', 'Ask for more', 'Jump and jive', 'Three dozen', 'More than eleven', 'Christmas cake', 'Climb the steps', 'Naughty forty',
  'Time for fun', 'Winnie the Pooh', 'Down on your knees', 'Droopy drawers', 'Halfway there', 'Up to tricks', 'Four and seven', 'Four dozen', 'P.C.', 'Half a century',
  'Tweak of the thumb', 'Danny La Rue', 'Stuck in the tree', 'Clean the floor', 'Snakes alive', 'Was she worth it', 'Heinz varieties', 'Make them wait', 'Brighton line', 'Five dozen',
  "Baker's bun", 'Turn the screw', 'Tickle me', 'Red raw', 'Old age pension', 'Clickety click', 'Stairway to heaven', 'Saving grace', 'Either way up', 'Three score and ten',
  'Bang on the drum', 'Six dozen', 'Queen bee', 'Candy store', 'Strive and strive', 'Trombones', 'Sunset strip', "Heaven's gate", 'One more time', 'Eight and blank',
  'Stop and run', 'Straight on through', 'Time for tea', 'Seven dozen', 'Staying alive', 'Between the sticks', 'Torquay in Devon', 'Two fat ladies', 'Nearly there', 'Top of the shop',
]);

const DIGITS = ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine'];
const capitalize = s => s[0].toUpperCase() + s.slice(1);
const digitsOf = n => `${DIGITS[Math.floor(n / 10)]} and ${DIGITS[n % 10]}`;

/** Ways of calling a number. 'number' is the default: just the number, no phrase. */
export const CALL_STYLES = Object.freeze([
  { key: 'number', label: 'Number only', example: '“Number 22”' },
  { key: 'digits', label: 'Digits too', example: '“Two and two, 22”' },
  { key: 'traditional', label: 'Traditional', example: '“Two little ducks… 22”' },
]);
export const DEFAULT_CALL_STYLE = 'number';

/** The words to show on screen and to speak for `n` in the given style. */
export function describeCall(n, style = DEFAULT_CALL_STYLE) {
  switch (style) {
    case 'digits':
      return n < 10
        ? { display: `Single number ${n}`, speech: `Single number, ${n}.` }
        : { display: `${capitalize(digitsOf(n))}, ${n}`, speech: `${digitsOf(n)}, ${n}.` };
    case 'traditional':
      return {
        display: TRADITIONAL_CALLS[n],
        speech: n < 10 ? `${TRADITIONAL_CALLS[n]}. Number ${n}.` : `${TRADITIONAL_CALLS[n]}. ${digitsOf(n)}, ${n}.`,
      };
    default:
      return { display: `Number ${n}`, speech: `Number ${n}.` };
  }
}
