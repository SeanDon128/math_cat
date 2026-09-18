# 1. Game Design Document — Math Cat

## Logline
A retro pixel-art math trivia game where you play as a cat racing up the grade levels — answer fast, answer right, and don't get demoted.

## Platform & Controls
- **Platform:** PC (Windows), single player
- **Resolution:** 1280×720, windowed or fullscreen
- **Input:** Keyboard and Xbox controller, both live/hot-swappable

| Action | Keyboard | Controller |
|---|---|---|
| Select green answer | `A` | `A` button |
| Select red answer | `B` | `B` button |
| Select blue answer | `X` | `X` button |
| Select yellow answer | `Y` | `Y` button |
| Highlight answer | Arrow keys (`Up` = Y, `Left` = X, `Right` = B, `Down` = A) | D-Pad / Left Stick |
| Confirm highlighted answer | `Enter` | `A` button |
| Pause | `Esc` | `Start` button |
| Back / Cancel | `Esc` | `B` button |

## Core Gameplay Loop
1. Title Screen → Press Start.
2. A question appears with four answer choices. Keyboard players use arrow keys to highlight a spatially matching choice, then press `Enter` to submit; A/B/X/Y keys and controller face buttons submit their matching choices directly.
3. Cat reacts instantly: **happy animation + chime** on correct, **sad animation + buzz** on incorrect. The selected answer button turns green for correct, red for incorrect, or blue when the correct selection triggers a promotion; answer text remains white in every state.
4. Progress bar/pips track correct answers (toward promotion) and incorrect answers (toward demotion) accumulated in the current grade. A separate row of hearts tracks the player's 9 lives for the session — each incorrect answer costs one life.
5. On promotion: **Level-Up screen** (blue banner, fanfare, new grade shown), then next question.
6. On demotion: **Demotion popup** (banner, sad stinger, new grade shown), then next question.
7. Session ends when the timer expires **or** all 9 lives are lost → **Game Over screen** with score, grade reached, end reason, and high score check.
8. Return to Title.

## Session / Win-Loss Model
The rules in this section describe Standard play; Blitz has its own rules below.

Math Cat is a score-attack game with two independent end conditions, whichever comes first:
- **Timer:** Default session length **120 seconds** (`SESSION_TIME_SEC` constant, easy to tune). Timer pauses during Level-Up/Demotion popups and Pause menu so feedback isn't rushed.
- **Lives:** The player starts each session with **9 lives** (`START_LIVES` constant). Every incorrect answer removes exactly 1 life, regardless of its effect on grade demotion. Reaching 0 lives ends the session immediately.
- Game Over records final score, grade reached, and the triggering reason (time expired vs. out of lives) to the high score table.

## Scoring
- **+`10 × current_grade`** points per correct answer (higher grades = more valuable, rewards climbing).
- **+50 bonus** on every promotion.
- **0** points on incorrect answers (no penalty beyond grade-counter/demotion effects).
- High score table stores top 10 runs: score, grade reached, date.

## Blitz Mode

Blitz is a separate fixed-grade score attack available from the title menu, with solo selected by default and optional local two-player competition. Select any existing Grade 1-13 question pool. A round lasts exactly 120 seconds from first-question readiness; opening the menu or Options does not stop time.

In solo play, correct answers add 1 and incorrect answers subtract 1. Scores can be negative. Either answer immediately advances to the next question, with sound and nonblocking status feedback but no reveal delay. There are no lives, grade changes, time bonuses, or victory threshold.

At time-up, show the selected grade, net score, answer totals, and accuracy. Each grade has its own local top-10 board, ordered by score descending and earlier submission first for ties. Only positive scores from completed rounds qualify. Qualifying players can save exactly three A-Z initials (duplicate initials allowed) or skip entry. Restart and quit abandon the current run; Retry retains the selected grade.

Blitz does not change Standard best scores, career statistics, or achievements. Existing question pools, grade-specific cat/background/music, input preferences, and settings are reused. Online competition and anti-cheat are not part of this mode.

### Two-player rules

Choose two players from Blitz setup, using either a shared keyboard (P1 WASD, P2 arrows) or two explicitly joined controllers (Y or D-pad Up, X or D-pad Left, B or D-pad Right, A or D-pad Down). Each direction/face button submits directly, independently of the solo controller navigation preference. Players share the same question and answer choices, with separate scores/cats and labeled feedback.

Two-player play uses the solo composition: one equation at the top center and one shared gold/up, blue/left, red/right, and green/down answer diamond over a full-width grid. Player 1's orange cat sits on the left and Player 2's blue cat on the right, each with a separate score, reaction, and lockout status. The diamond always shows only Y/X/B/A, whether using keyboard, face buttons, or D-pad. Shared answers remain unchanged when one player is locked out. The cat palettes do not inherit the solo Cat Color setting, so identity remains clear after changing options or restarting.

The first accepted correct answer wins +1 and closes the question. A wrong answer costs -1 and locks that player out for that question; it does not reveal the correct answer to the opponent. Advance after the first correct answer or both players answering incorrectly. If only one player attempts incorrectly, wait for the opponent or time-up. Input received during replacement-question presentation is discarded, not applied to the unseen question.

The higher score wins after 120 seconds. Draws have no winner or score submission. Only a positive, top-10 qualifying winner can enter initials on the separate two-player per-grade board; a positive-scoring loser cannot submit. Save/skip/retry behavior matches solo.

Controller-only play includes setup, joining, menus/options, hot-plug recovery, initials, save retry/skip, and rematches. Connected controllers retain their player slots; a replacement presses A to claim a vacant slot while the recovery message is visible. Time keeps running after disconnects and in shared menus. Either controller can manage menus/results, including a newly connected controller when both original devices are gone. Rematches preserve grade/control mode and valid assignments, and wait for missing controllers before the next clock starts. Mixed keyboard/controller matches and online play are out of scope.

## Grade Progression Rules (summary — full algorithm in doc 5)
- Start at **Grade 1**. Floor is Grade 1 (can never drop below).
- **5 correct answers** in current grade → promote 1 grade, reset the grade counters.
- **3 incorrect answers** in current grade → demote exactly **1 grade**.
- The incorrect-answer (demotion) counter resets to 0 upon promotion.
- Correct/incorrect grade counters reset to 0 after every promotion or demotion event.
- Independently of grade, every incorrect answer also removes 1 of the player's 9 session lives (see Session / Win-Loss Model above).

## Grade Content — Current Scope (Grades 1–5)
| Grade | Topics |
|---|---|
| 1 | Addition with two operands from 1–10 (sums 2–20); 200 unique prompt-and-choice sets from 100 ordered prompts, each with two distractor variants |
| 2 | Subtraction with minuends from 1–20 and nonnegative results; 200 unique prompt-and-choice sets from 100 prompts, emphasizing single-digit pairs |
| 3 | Multiplication (`×`) with operands from 0–10; 220 unique prompt-and-choice sets from 110 ordered prompts, each with two distractor variants and no negative choices |
| 4 | Exact division (`÷`) with denominators 1–10 and answers 0–10; 200 unique prompt-and-choice sets from 100 prompts |
| 5 | 200 unique prompt-and-choice sets: two-digit addition/subtraction (negative subtraction answers allowed), two-digit `×` one-digit multiplication, like-denominator fraction addition, and decimal addition/subtraction with operands below 100 |

Across Grades 2–5, choices are shuffled and the correct answer is numerically lowest in 25% of sets, highest in 25%, and between wrong answers in 50%. Grade 5 uses a balanced mixed-topic deck with 50 questions for each topic group. Grades 6–13 use a placeholder scaling deck so the full Math Kitten → Math Cat → Math Tiger → Professor Whiskers evolution chain is reachable; real per-grade curricula remain a planned follow-up.

Grades 6–12 are documented in doc 4's data model for future versions, but are **out of scope for the jam build**.

## Screens
- **Title Screen** — logo, green "Start Game" button, high score teaser, controller/keyboard hint.
- **Gameplay Screen** — question, four value-only answer buttons arranged around a centered Xbox-style A/B/X/Y face-button diamond, cat, HUD (grade, score, timer, lives, grade-counter pips), and a subtle grade-evolving synthwave perspective-grid background.
- **Level-Up Screen** (overlay/popup, ~1.5–2s or button-skip) — "Promoted to Grade X!", happy cat, fanfare.
- **Demotion Popup** (overlay, ~1.5–2s) — "Demoted to Grade X", sad cat, stinger.
- **Pause Menu** — Resume, Restart, Quit to Title, (stretch: volume sliders). The Resume button has no inline input hint.
- **Game Over Screen** — final score, grade reached, correct/incorrect totals, high score entry/list, Retry and Title Screen buttons. Retry has no inline input hint.

## Visual & Audio Direction
- Palette: ~32-color GBC-era palette, black or dark-navy outlines, warm classroom-adjacent accent colors. Grades 1–2 use only a black field and violet neon perspective grid. Grades 3–4 transition to a purple Kitten grid with a gradual dark-purple sky fade, faint purple horizon glow, and a few stars; Grades 5–8 add dark purple sky, denser blue stars, and brighter orange. Occasional white/cyan pixel shooting stars begin at Grade 7. Grades 9–12 shift to yellow grid lines with magenta/deep-blue horizon glow and slightly more shooting stars; Grade 13+ uses white grid lines with pink/purple sky, cyan mathematical constellations, gentle twinkles, and the highest restrained shooting-star rate. Every visual-stage transition, including Grade 2↔3, cross-fades over 4.8 seconds. Grid lines scroll toward the horizon, fade with distance, and use denser horizontal bands to keep the upper playfield calm while preserving the feeling of advancing into the world.
- Cat: simple, expressive, 2–4 frame animations (idle, happy, sad, blink).
- Music: upbeat chiptune loop for gameplay, calmer loop for title; short jingles for level-up/demote/game-over.
- Full lists in docs 7 (art) and 8 (sound).
