# 10. Backlog — MoSCoW Prioritization

## Build V1 In This Exact Order
1. **Open the scaffold in Godot:** In Godot Project Manager, click **Import**, select [project.godot](../project.godot), then open it. Confirm Project Settings shows a `1280 x 720` viewport and that `GameManager` and `ProgressionManager` appear under the **Autoload** tab. Do not make art yet.
2. **Verify the rule systems first:** `ProgressionManager` is the first component to build and test because every gameplay answer depends on it. In a temporary scene or by adding temporary `print()` statements, verify 5 correct answers promote, 3 incorrect answers demote by 1, Grade 1 never drops lower, and changing grade clears the two grade counters.
3. **Create a plain gameplay scene:** Build `scenes/game/game.tscn` as a `Control` scene with a question `Label`, four value-only `Button` nodes arranged around a centered Xbox-style A/B/X/Y face-button diamond, and labels for grade, score, timer, and lives. Use plain Godot controls and colors; this is the first visible playable surface.
4. **Wire one static Grade 1 question:** Put `2 + 3 =` and four answers in the scene script. Make the correct button call `GameManager.register_answer(true)` and every other button call `GameManager.register_answer(false)`. Disable the buttons briefly after a click so one answer cannot be submitted twice.
5. **Test keyboard and Xbox actions:** Use the `answer_1` through `answer_4` actions configured by `scripts/main.gd` to activate the same button handlers. Test direct A/B/X/Y keyboard and Xbox face-button answers. During gameplay, test arrow-key highlighting (`Up` = Y, `Left` = X, `Right` = B, `Down` = A) and `Enter` submission of the highlighted answer.
6. **Connect the HUD:** Listen to `GameManager` and `ProgressionManager` signals to update grade, score, 120-second timer, 9 hearts/lives, and the 5-correct/3-incorrect progress pips. Confirm each wrong answer removes one life.
7. **Handle game end first:** When the timer hits zero or the ninth life is lost, stop accepting answers and show a basic Game Over panel with final score, grade, and end reason. Add a `Retry` button that calls `GameManager.start_session()` and a `Title Screen` button that returns to the title scene; neither button displays an inline input hint.
8. **Replace the static question with Grade 1 generation:** Create `QuestionData`, `AdditionGenerator`, and the smallest possible `QuestionBank`. Randomly serve a shuffled deck of 200 unique prompt-and-choice sets: 100 ordered addition prompts, with both operands from 1–10, each paired with two distinct distractor variants. Generate four shuffled choices: one correct answer and three close wrong answers; make the correct answer numerically lowest in 25% of sets, highest in 25%, and between wrong answers in 50%.
9. **Add Grade 2 through Grade 5:** Done for the current core loop: Grade 2 has a 200-set subtraction deck with minuends 1–20 and extra single-digit coverage; Grade 3 has a 220-set multiplication (`×`) deck with 0–10 operands and no negative choices; Grade 4 has a 200-set exact-division (`÷`) deck with denominators 1–10 and answers 0–9; Grade 5 has a 200-set mixed deck of multi-digit arithmetic, fractions, and decimals. All use shuffled close choices with a 25% lowest, 25% highest, and 50% middle correct-answer rank. Basic geometry remains deferred. Grades 6–13 now use `AdvancedPlaceholderGenerator` (a single scaling `×` deck per grade) so the full Math Kitten → Math Cat → Math Tiger → Professor Whiskers evolution chain is reachable; swap in real per-grade curricula later.
10. **Add promotion and demotion overlays:** Implement simple text popups inside `game.tscn`. They pause the timer while visible, then return to `PLAYING`. Text-only is enough at this stage.
11. **Add the title and pause screens:** Done. The green `Start Game` button starts a session with Enter or Xbox A. Pause has Resume, Restart, and Quit to Title; Resume has no inline input hint. Menus use Up/Down or D-pad navigation and Enter/A activation, with Esc/Start resuming play.
12. **Add feedback polish:** Done for color feedback: the selected answer button turns green for correct, red for incorrect, or blue when the correct answer triggers a promotion; answer text stays white in every state. Its matching central Xbox A/B/X/Y glyph remains fully opaque while the other three fade, then all four reset for the next question. The four Math Cat forms now use a shared 64×64 pixel-art atlas with idle, happy, sad, level-up, game-over, and evolution-pose animations. Add placeholder sounds next.
	- Level-up time bonus is also done: `GameManager` immediately adds `10 × completed grade` seconds on an actual promotion, refreshes the timer via `timer_tick`, and emits `time_bonus_awarded` for the floating `+N Seconds!` notification. No bonus is awarded for a repeat promotion at Grade 13.
13. **Add high scores only if time remains:** Implement `SaveManager` and a top-10 local score list. It is valuable polish, not required to prove the game loop.
14. **Play five complete sessions and export:** Test timer expiry, zero-lives expiry, promotions, Grade 1 demotions, pause/resume, Retry, title navigation, keyboard, and controller. Export a Windows build only after those checks pass.

## Must Have (MVP — the game does not exist without these)
- [ ] Godot project set up at 1280×720 with keyboard + controller Input Map
- [ ] `GameManager` state machine (Title/Playing/Popups/Paused/GameOver)
- [ ] `ProgressionManager` grade-counter/demotion algorithm (doc 5), Grades 1–13, floor at Grade 1, flat 1-grade demotion
- [ ] Question generators: Addition (G1), Subtraction (G2), Multiplication (G3), exact division (G4), and multi-digit add/subtract, multi-digit multiplication, like-denominator fraction addition, and decimal add/subtract (G5)
- [ ] 4-answer selection UI, keyboard (A/B/X/Y and arrows) + controller (A/B/X/Y) input
- [ ] Correct/incorrect feedback (even a color flash + placeholder sound is enough for MVP)
- [ ] Score tracking + display
- [ ] 2-minute session timer + 9-life system (1 life lost per incorrect answer) + Game Over trigger on timeout or 0 lives
- [ ] Title Screen (Press Start)
- [ ] Game Over Screen (score, grade reached, end reason, Retry/Title)
- [x] Compact gameplay HUD: no gameplay title; score and time in a clear header; nine pixel heart containers for lives; and green five-pip/red three-pip grade progress at upper left.

## Should Have (expected in a "complete" jam submission, do right after MVP)
- [x] Four-stage Math Cat evolution system (Math Kitten Grades 1–4, Math Cat 5–8, Math Tiger 9–12, Professor Whiskers 13+); scene-local `CharacterEvolutionManager` maps `ProgressionManager` grade changes through `MathCatStages.stage_for_grade()`, selects stage-specific atlas resources, plays level-up or signature evolution-pose animations, and leaves `game.gd` to show the evolution banner
- [x] Pause and New High Score are now real Math Cat animation states: `play_pause()`/`play_high_score()` loop until explicitly replaced (`_pause_game()`/`_resume_game()` in `game.gd`). `GameManager.best_score` tracks an in-memory session best and emits `new_high_score`, which swaps the Game Over cat animation and shows a "NEW HIGH SCORE!" banner instead of the normal game-over pose; this best score does not persist across app launches yet (see High score persistence below).
- [x] Grade-evolving synthwave background: one full-screen procedural shader draws a subtly moving perspective grid and horizon; `BackgroundEvolutionManager` maps Grade 1/5/9/13 thresholds to Kitten/Big Cat/Tiger/Nerd Cat palette and effects, cross-fading tier changes over 2.4 seconds without per-frame script work.
- [x] Background motion and atmosphere polish: the perspective grid now travels away from the player toward the horizon at its original speed. Pixel-art shooting stars begin at Grade 7, scale through low/medium/high frequency bands at Grades 7/9/13, remain clipped to the sky behind gameplay UI, and reuse the single procedural background shader.
- [ ] Level-Up popup/screen with distinct feedback
- [ ] Demotion popup with distinct feedback
- [ ] Pause menu (Resume/Restart/Quit)
- [ ] High score persistence (local JSON save/load, top 10 list)
- [x] Cat idle/happy/sad/level-up/game-over/evolution-pose pixel-art animations (four 64×64 frames per animation and evolution stage)
- [x] Core SFX set: AudioManager synthesizes `correct_answer`, `incorrect_answer`, `level_up`, `demotion`, and `ui_confirm` through a five-player SFX pool; gameplay/progression signals and menu action handlers trigger the relevant cue.
- [ ] Answer button visual states (normal/correct-flash/incorrect-flash) with real pixel art
- [x] Streak progress indicator (five green promotion pips and three red demotion pips) and nine-heart lives indicator in HUD

## Could Have (polish, only if Day 2 goes smoothly)
- [ ] Title/gameplay background music loops
- [ ] Full pixel-art backgrounds per screen (vs. placeholder/solid color)
- [ ] Per-grade backdrop tint/motif variants
- [ ] Confetti/particle effect on level-up
- [ ] Input-glyph swapping based on last-used device (keyboard vs. controller icons)
- [ ] Settings: SFX/music volume sliders in pause menu
- [ ] Timer-warning SFX in final 10 seconds
- [ ] Larger "hero pose" cat art for Level-Up/Demotion popups (vs. reusing gameplay sprite)
- [ ] Alternate feedback copy for repeat promotions at MAX_GRADE / repeat demotions at MIN_GRADE ("Mastered Grade 13!")
- [ ] Colorblind-safe answer feedback (icon/shape in addition to color)

## Won't Have (explicitly out of scope for this jam)
- Real Grades 6–13 curricula (currently a scaling placeholder `×` deck — architecture supports swapping in real content later, see doc 4)
- Any online/cloud leaderboard or multiplayer
- Mobile/console ports beyond PC + Xbox controller
- Full curriculum accuracy review / educator validation
- Localization (multi-language)
- Achievements/unlockables system
- Accessibility features beyond basic colorblind-safe flag above (e.g., full screen-reader support, remappable controls UI)
- Save-file cloud sync or multiple player profiles

## How to Use This List
Work top-to-bottom within each tier. Never start a "Should" item while a "Must" item is incomplete. If Day 2 is running behind schedule (doc 9), the cut order is: Could-have (all) → then trim Should-have starting from the bottom of that list.
