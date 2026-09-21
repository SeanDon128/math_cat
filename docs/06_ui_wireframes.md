# 6. UI Wireframes (1280×720)

All wireframes assume a 1280×720 canvas. Boxes are approximate proportions, not pixel-exact.

## Blitz Screens

The title menu order is RETRO MODE, BLITZ, ADVENTURE, OPTIONS, STATS, ACHIEVEMENTS, EXIT GAME. BLITZ matches the gameplay Y box's mustard yellow, ADVENTURE is dark pink, and ACHIEVEMENTS is dark orange. START BLITZ is green in both setup and controller join views.

```text
BLITZ MODE
120 seconds. +1 correct / -1 wrong. No lives. Time runs even in menus.
Grade Level       < 1 ... 13 >
Players           < 1 PLAYER / 2 PLAYERS >
Controls          < SHARED KEYBOARD / TWO CONTROLLERS >  (two-player only)
[ START BLITZ ]
[ HIGH SCORES ]
[ BACK ]
```

HIGH SCORES opens a local top-10 board with its own grade slider, Solo/Two Players selector, rank/initials/score rows, and Back to setup. An empty board explicitly invites the first positive score. Existing focus navigation works with keyboard, controller, and mouse.

Gameplay retains the existing question/answer layout but shows BLITZ, GRADE, signed SCORE, and TIME. Hearts and grade-progression pips are hidden. Opening the menu shows `BLITZ: TIME KEEPS RUNNING` with the countdown inside the padded menu layout, above the heading rather than across the panel border. The notice moves into Options while it is open and returns on Back; expiry closes all menus and shows results.

```text
BLITZ COMPLETE
Grade 4   |   Score: 25   |   120 seconds
Correct: 30   Incorrect: 5   Accuracy: 86%

LOCAL HIGH SCORE ENTRY
        [ C ] [ A ] [ T ]
[ SAVE SCORE ]     (or RETRY SAVE after a storage error)
[ SKIP ]
```

Type A-Z on a keyboard; Backspace/Delete edits a slot, and Enter confirms Save Score. On a controller, Left/Right selects a slot, Up/Down cycles letters, and A advances to the next slot or Save Score. B/Esc skips without recording a placeholder. The initials control consumes letter input before gameplay/menu shortcuts.

After saving, skipping, or a nonqualifying result, display the grade board with the newly saved row highlighted when applicable, plus RETRY BLITZ and TITLE SCREEN. Nonpositive scores never prompt for initials. Read/save errors are visible, not presented as empty or successfully saved boards.

### Two-player gameplay and results

```text
BLITZ                       TIME 00:42
GRADE 4
 ORANGE CAT              SHARED EQUATION               BLUE CAT
P1 SCORE 5                                          P2 SCORE 3
 Last result                                          Last result
 Lockout status                                       Lockout status
                          GOLD ANSWER
                               Y
                  BLUE ANSWER X   B RED ANSWER
                               A
                          GREEN ANSWER
                   ONE FULL-WIDTH PERSPECTIVE GRID
```

Two-player gameplay uses the single-player composition: one centered equation and one shared answer diamond over a full-width grid. Player 1's orange cat sits on the left and Player 2's blue cat on the right, with separate scores and feedback below each cat. Long questions wrap and reduce font size within the space between the cats. The central glyphs always show only Y/X/B/A, including in keyboard mode and regardless of the solo input preference. Controller face buttons and matching D-pad directions submit immediately; there is no shared answer focus or mouse-answer shortcut. Keyboard WASD/arrows remain supported and are explained in setup.

BLITZ/grade keeps the solo two-line heading, with one centered timer and no global score. Each player's score uses 32-point text with the abbreviated labels `P1 SCORE #` and `P2 SCORE #`, above the feedback and lockout rows. A wrong attempt shows `LOCKED OUT - NEXT QUESTION` beside the answering player's cat. Shared tiles and glyphs stay unchanged so the opponent can still answer without a revealed solution. The lockout label clears when the next question appears. Solo restores its original question width, timer, score, cat, and controls.

Shared answer tiles retain their solo 198-by-80-pixel dimensions and original centers at 1280x720. Wrapped text is fitted without enlarging or moving the tiles. Controller recovery uses a separate notice below the timer (or the menu footer), without hiding either player's feedback.

The answering player's cat uses the same happy/sad sprite animations and frame timing as Retro, without extra smooth position tweens. The opponent is unaffected. Pause, results, and rematch retain their shared sprite animation states.

After either player answers correctly, only the correct choice retains a filled background and visible outline; incorrect choices become transparent. When both players answer incorrectly, both selected wrong choices remain red for the feedback hold, the correct answer is revealed in grey, and unselected incorrect choices become transparent. This works in either answer order, including both players choosing the same wrong answer. Answer text stays visible. A lone wrong answer stays filled red while the opponent can still answer. The next question restores the normal answer backgrounds and outlines.

Two-player controls default to Two Controllers, with Shared Keyboard available as an alternative. Controller setup shows both joined device slots, Start (disabled until both join), and Back. A visible in-game recovery message names missing slots and explains that a new controller can press A to join without taking an occupied slot. Start opens the shared menu; time continues. If a rematch is waiting for controllers, B/Escape can return to title. Either controller can manage menus and results, including a replacement after all originals disconnect.

Two-player results show PLAYER 1 WINS, PLAYER 2 WINS, or DRAW, then grade/duration and both players' scores/answer totals/accuracy. Only a positive qualifying winner sees the labeled winner's initials prompt. Draws, nonpositive winners, and nonqualifying winners proceed to the separate two-player board. Retry preserves the two-player setup; Title returns to a fresh solo-default setup.

All two-player results screens use 32-pixel section gaps after the winner or draw announcement and after the player statistics, before either initials entry or the leaderboard. This includes empty leaderboards, nonqualifying scores, and saved scores. A further 32-pixel gap separates the leaderboard (or saved-score status) from the stacked Retry and Title buttons. Result boards with more than five scores use two columns: ranks 1-5 on the left and 6-10 on the right, retaining the original text size and saved-rank highlight. Up/down selects the actions with the keyboard, D-pad, or stick. Solo results and the title-screen leaderboard layout are unchanged.

## Title Screen
```
┌──────────────────────────────────────────────────────────────────────────┐
│                                                                            │
│                         [ 8-BIT "MATH CAT" LOGO ]                        │
│                            (cat mascot art)                              │
│                                                                            │
│                            [ Start Game ]                                │
│                             (green button)                               │
│                                                                            │
│                     Best Score: 480  (Grade 4)                           │
│                                                                            │
│               [KB icon] Keyboard      [Controller icon] Xbox             │
└──────────────────────────────────────────────────────────────────────────┘
```

## Gameplay Screen
```
┌──────────────────────────────────────────────────────────────────────────┐
│ GRADE 3                            SCORE 230  TIME 01:12  LIVES: ♥♥♥♥♥♥♥♡♡ │
│ CORRECT   ● ● ● ○ ○                                                    │
│ INCORRECT ● ○ ○                                                        │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│                  ┌────────────────────────────────────┐                  │
│                  │              7 × 8 = ?              │                  │
│                  └────────────────────────────────────┘                  │
│                                                                            │
│                         ┌───────────────┐                                │
│                         │      48       │                                │
│                         └───────────────┘                                │
│        ┌───────────────┐      (Y)      ┌───────────────┐                 │
│        │      63       │   (X)   (B)   │      56       │                 │
│        └───────────────┘      (A)      └───────────────┘                 │
│                         ┌───────────────┐                                │
│                         │      54       │                                │
│                         └───────────────┘                                │
│                                                                            │
│                         🐱  (cat idle sprite, bottom center)              │
└──────────────────────────────────────────────────────────────────────────┘
```
- The title is intentionally omitted during gameplay. The compact two-row header leaves room for the enlarged question panel and answer diamond.
- Correct pips: five pixel circles fill green toward promotion. Incorrect pips: three pixel circles fill red toward demotion. On a promotion or demotion, the completed row flashes white, its original color, white, then its original color in 0.15-second steps before remaining visible until the next question resets it.
- Lives: nine pixel heart containers sit at the header's upper right, 10 px below the Grade baseline. Filled hearts are remaining lives; muted empty containers are lost lives.
- The question panel uses a larger autowrapping font so fractions and decimal questions remain readable.
- The header and question panels remain in the scene tree with transparent fill and borders, preserving a future accessibility styling hook without visually boxing in the play area.
- Grade, Score, Time, and Lives use the same 24 px font size. Score and Time sit 40 px above Grade in fixed center-region positions, with Score 60 px left and Time 25 px right of their prior positions; this prevents a longer score from shifting Time. Lives remains aligned with Grade, shifted 10 px left, and its heart containers sit 10 px lower.
- During answer feedback, only the selected value button changes color: green for a correct selection, red for an incorrect selection, or blue for a correct selection that triggers a promotion. Answer text remains white in every state.

## Level-Up Popup (overlay on gameplay)
The Level-Up banner and feedback text use blue.
```
┌──────────────────────────────────────────────────────────────────────────┐
│                    ░░░░░░░░ dim backdrop ░░░░░░░░                        │
│                    ┌──────────────────────────┐                          │
│                    │      ⭐ LEVEL UP! ⭐      │                          │
│                    │   Promoted to Grade 4!    │                          │
│                    │                            │                          │
│                    │      🐱 (happy, big)       │                          │
│                    │                            │                          │
│                    │     Get ready...           │                          │
│                    └──────────────────────────┘                          │
└──────────────────────────────────────────────────────────────────────────┘
```

## Demotion Popup
```
┌──────────────────────────────────────────────────────────────────────────┐
│                    ░░░░░░░░ dim backdrop ░░░░░░░░                        │
│                    ┌──────────────────────────┐                          │
│                    │      💔 OH NO! 💔          │                          │
│                    │   Demoted to Grade 1       │                          │
│                    │                            │                          │
│                    │      🐱 (sad, big)          │                          │
│                    │                            │                          │
│                    │     Keep trying...          │                          │
│                    └──────────────────────────┘                          │
└──────────────────────────────────────────────────────────────────────────┘
```

## Pause Menu
```
┌──────────────────────────────────────────────────────────────────────────┐
│                    ░░░░░░░░ dim backdrop ░░░░░░░░                        │
│                    ┌──────────────────────────┐                          │
│                    │         PAUSED             │                          │
│                    │                            │                          │
│                    │          Resume             │                          │
│                    │          Restart            │                          │
│                    │          Quit to Title      │                          │
│                    └──────────────────────────┘                          │
└──────────────────────────────────────────────────────────────────────────┘
```

## Game Over Screen
```
┌──────────────────────────────────────────────────────────────────────────┐
│                            GAME OVER                                     │
│                                                                            │
│                      Final Score:  480                                   │
│                  Highest Correct Streak: 12                              │
│                  Total Correct Answers: 28                               │
│                  Total Incorrect Answers: 9                              │
│                      Accuracy: 76%                                       │
│                    Time Survived: 01:43                                  │
│                  Evolution Stage: Math Cat                               │
│                    Reason: Out of Lives                                  │
│                                                                            │
│                        HIGH SCORES                                       │
│                     1. 480  Grade 4  (NEW!)                              │
│                     2. 410  Grade 3                                      │
│                     3. 350  Grade 4                                      │
│                                                                            │
│                    [ Retry ]    [ Title Screen ]                         │
└──────────────────────────────────────────────────────────────────────────┘
```

## Layout Notes
- All panels use a consistent 9-slice pixel-art frame (see doc 7) for visual cohesion.
- Answer buttons show only the numeric choice. A noninteractive central circular diamond shows the Xbox face-button glyphs: `Y` on top, `X` left, `B` right, and `A` on bottom. After an answer is selected, its matching glyph remains fully opaque while the other three fade; a new question restores all four. Arrow keys highlight the matching spatial answer; `Enter` submits the highlighted answer. The matching A/B/X/Y letter key and Xbox face button submit their associated answer directly.
- Keep text large and high-contrast (dark outline + light fill or vice versa) — this is a math game, legibility of numbers matters more than font flair.
- The Results panel highlights `Highest Correct Streak` in gold. Correct/incorrect totals and accuracy reflect every submitted answer; `Time Survived` counts active gameplay time rather than remaining timer time, so time bonuses do not inflate it. Evolution Stage reflects the highest grade reached during the session.
