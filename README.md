# Housey

A Housey (Tambola / Housie) game for the browser that tries to look and feel like playing at a real table: a cloth bag of wooden number coins, paper tickets you dab with ink, a printed caller's board with red chips, and a caller who reads out the traditional calls ("Two little ducks… twenty-two").

## Play

Play at [housey.webappslab.com](https://housey.webappslab.com/). There's no build step: the site is plain HTML, CSS and JavaScript modules. To run it locally, serve the folder (browsers don't load JavaScript modules from `file://`):

```bash
npm start                      # or: python3 -m http.server 8080
```

### What's on the site

- **The game** (`index.html`): play against friendly computer players. Choose the caller's speed and voice, and pick up where you left off if the page is refreshed or closed.
- **Number caller** (`caller.html`): draws and reads out numbers for your own game on paper tickets. Auto or tap-to-call, undo, full screen for a TV, and a ticket checker for prize claims.
- **Print tickets** (`print.html`): as many tickets as you need (up to 600), in your colours and layout, or from a preset. Print or save as PDF, and download a list of the codes.
- **My tickets** (`ticket.html`): open a printed ticket on a phone by scanning its QR code or typing its code, and dab it on screen.

Every ticket has a code like `HNZV-C92Z`. The code *is* the ticket: the numbers are generated from it, so any device can rebuild and check a ticket without a server. A check letter catches typos.

### Offline and installing

When it's served over the web (for example GitHub Pages), the game saves itself on your device the first time you open it, and after that it works with no internet connection. To get an app icon:

- **Android (Chrome):** menu ⋮ → **Install app** (or **Add to Home screen**).
- **iPhone/iPad (Safari):** Share → **Add to Home Screen**.
- **Desktop (Chrome/Edge):** click the install icon in the address bar.

Updates download in the background and show up the next time you open the game.

1. Pick your number of tickets, how many players sit at the table, and how fast the caller goes (or choose **I'll tap** to draw each coin yourself).
2. When a number is called, tap it on your ticket to dab it.
3. Finish a prize (Early Five, Top/Middle/Bottom Line, Full House) and press its button to claim it before the other players do. Claim one you haven't got and you get a "Bogey!".

Space bar pauses or resumes (or draws the next coin in tap mode).

## Develop

```bash
npm install
npm run check      # lint + tests (the Web app workflow runs the same on every push)
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for how the code is organised and the plan for online play.

## Mobile app

`mobile/` holds a native Flutter version of the game for Android and iOS. See [mobile/README.md](mobile/README.md) to run or build it.

## Files

- `index.html`: page structure
- `style.css`: textures and look (wood, felt, paper, ink, coins)
- `game.js`: ticket generation, the caller, computer players, claims, and sound (made with Web Audio, so there are no audio files)
- `sw.js`, `manifest.webmanifest`, `icons/`: offline support and the installable app
- `fonts/`: local copies of the fonts (from Google Fonts, SIL Open Font License) so text looks right offline
- `how-to-play.html`, `tambola-calls.html`: the Tambola rules and the list of all 90 traditional calls
- `privacy.html`, `terms.html`, `support.html`: information pages
- `robots.txt`, `sitemap.xml`, `404.html`, `og-image.jpg`, `screenshots/`: search engines, link previews and install screens
- `mobile/`: the Flutter app for Android and iOS

## Search engines

Each page has its own title, description and canonical URL, plus Open Graph tags so shared links show a preview card. The home page carries schema.org structured data (the game, the website and an FAQ), and the sitemap lists every page. If you add a page, add it to `sitemap.xml`. Add every new page, script or stylesheet to the `FILES` list in `sw.js` and bump its `VERSION` (a test fails if you forget).
