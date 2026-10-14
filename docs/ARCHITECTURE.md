# Architecture and roadmap

Housey is a static site: plain HTML, CSS and native JavaScript modules, with no build step. This page covers how the code is laid out and how the current design prepares for online play with a backend and database.

## Layers

```
js/
  core/       Rules and data. No DOM, no storage, no network. Runs in browsers and Node.
  services/   Things with side effects: storage, settings, speech, sound, ticket lookup.
  ui/         Reusable pieces of the screen, built on core + services.
  pages/      One entry script per HTML page. Wires ui + services together.
  vendor/     Third-party code, checked in (see README).
```

Dependencies only point downwards: `pages → ui → services → core`. Nothing in `core/` imports from the other folders, so it can be tested in Node (`tests/`) and reused unchanged by a future server.

| Module | Responsibility |
| --- | --- |
| `core/ticket-code.js` | Ticket codes (`HNZV-C92Z`): create, clean up, check, read from links and QR text |
| `core/tickets.js` | Ticket grids, generated from a code with a seeded random source |
| `core/number-draw.js` | The bag of 90 numbers: draw, undo, save and load |
| `core/prizes.js` | Prizes and the rule for each |
| `core/calls.js` | What the caller shows and says, in each call style |
| `core/print-options.js` | Print colours, layouts and presets, with range checks |
| `services/storage.js` | localStorage with versioned records (old or damaged data is ignored, never a crash) |
| `services/settings.js` | Player preferences with defaults and limits |
| `services/speech.js` | The caller's voice (browser text-to-speech) |
| `services/ticket-service.js` | Looking up tickets and making ticket links: the seam for the backend |

## Decisions made with online play in mind

1. **Ticket codes are permanent IDs.** Today a code is the seed the numbers are generated from, so a printed ticket can be opened or checked on any device with no server. The seed includes a generator version (`housey-ticket-v1:`), and `tests/tickets.test.js` pins a known code to its numbers, so a change that would alter printed tickets fails the tests. A server can later issue codes in the same format (or a new version) and store the numbers.
2. **Ticket lookup is async and in one place.** `findTicket()` in `services/ticket-service.js` returns a Promise, so switching it to "ask the server, fall back to the local rebuild when offline" needs no change in the pages that call it.
3. **Game state is plain, serialisable data.** `NumberDraw` saves to `{ remaining, called }`; the game saves players, ticket codes, dabs and prizes. The `called` list is effectively an event log (draw 1, draw 2, …), which is what a server would broadcast to players.
4. **Storage goes through versioned records.** `versionedRecord(key, version)` wraps every saved game, caller session and ticket list. A schema change bumps the version instead of breaking old saves, and a record can be replaced by a server-synced version without touching pages.
5. **Rules live in `core/`.** A Node backend can import the same modules to generate tickets and verify prize claims, so client and server can never disagree on the rules.

## Roadmap to online play

### Phase 1: backend and accounts
- A Node service (it can import `js/core/` directly) with PostgreSQL.
- Suggested tables:
  - `games (id, host_id, status, draw_order_secret, speed, created_at)`
  - `draws (game_id, seq, number, called_at)`: one row per call, the source of truth
  - `tickets (code PK, game_id NULL, owner_id NULL, grid JSONB, batch_id NULL, created_at)`
  - `ticket_batches (id, host_id, options JSONB, created_at)`: a print run
  - `claims (id, game_id, ticket_code, prize, status, checked_at)`
- `findTicket()` calls `GET /tickets/:code`, then falls back to `ticketFromCode()`.

### Phase 2: live rooms
- The number caller page becomes a room host: `POST /games`, then each draw is `POST /games/:id/draws`.
- Players open `ticket.html?t=CODE&game=ID` (the QR can carry both) and subscribe over WebSocket or Server-Sent Events. Called numbers then highlight on their tickets live.
- The draw order is generated and kept on the server, so nobody can see the next number.

### Phase 3: verified claims
- Players press a claim button; the server checks it with `meetsPrize()` against the `draws` table and announces the result to the room.
- First valid claim wins (ordered by server time), which settles disputes.

### Phase 4: offline first
- Local records become a cache with a small queue of pending actions to sync when back online.
- The Android app has no internet permission today (see `mobile/android/app/src/main/AndroidManifest.xml`). Online play means adding it back and updating the privacy policy and store data-safety answers.

### Not yet done (good next steps)
- Traditional "strips" of 6 tickets that use all 90 numbers exactly once, as a print option.
- Opening ticket links straight in the app (Android App Links and iOS Universal Links), which needs `.well-known` files on the website and the app's release signing key.

## The Flutter app

`mobile/` mirrors this layout: `lib/core` (rules), `lib/services` (storage, settings, sound and voice, the ticket PDF), `lib/game` (controllers) and `lib/ui` (screens). `lib/core/random.dart`, `ticket_code.dart` and `tickets.dart` are step-for-step ports of their `js/core` counterparts. Both test suites check `tests/fixtures/ticket-codes.json`, so a code makes the same ticket in the app and on the website. A change to ticket generation must update both, and the fixtures must not change.
