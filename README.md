# Housey

A Housey (Tambola / Housie) game for the browser that tries to look and feel like playing at a real table: a cloth bag of wooden number coins, paper tickets you dab with ink, a printed caller's board with red chips, and a caller who reads out the traditional calls ("Two little ducks… twenty-two").

## Play

Open `index.html` in any modern browser (phone or desktop). No install or build step is needed.

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

## Mobile app

`mobile/` holds a native Flutter version of the game for Android and iOS. See [mobile/README.md](mobile/README.md) to run or build it.

## Files

- `index.html`: page structure
- `style.css`: textures and look (wood, felt, paper, ink, coins)
- `game.js`: ticket generation, the caller, computer players, claims, and sound (made with Web Audio, so there are no audio files)
- `sw.js`, `manifest.webmanifest`, `icons/`: offline support and the installable app
- `fonts/`: local copies of the fonts (from Google Fonts, SIL Open Font License) so text looks right offline
- `how-to-play.html`, `tambola-calls.html`: the Tambola rules and the list of all 90 traditional calls
- `privacy.html`, `terms.html`, `support.html`, `legal.css`: information pages
- `robots.txt`, `sitemap.xml`, `404.html`, `og-image.jpg`, `screenshots/`: search engines, link previews and install screens
- `mobile/`: the Flutter app for Android and iOS

## Search engines

Each page has its own title, description and canonical URL, plus Open Graph tags so shared links show a preview card. The home page carries schema.org structured data (the game, the website and an FAQ), and the sitemap lists every page. If you add a page, add it to `sitemap.xml` and to the `FILES` list in `sw.js`.
