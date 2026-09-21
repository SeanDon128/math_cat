# 9. 2-Day Game Jam Development Schedule

Optimized for a **solo developer, first game**, prioritizing a playable MVP loop by end of Day 1, then polish/content/robustness on Day 2. Adjust clock times to your actual jam start; hour offsets matter more than literal clock times. Build in slack — first jam estimates always run long.

## Day 1 — Core Loop (Goal: playable, ugly, end-to-end game by end of day)
| Time | Task |
|---|---|
| Hr 0–1 | Project setup: Godot project, window/resolution settings, Input Map (keyboard+controller bindings), folder structure, git init/first commit. |
| Hr 1–2 | Autoload skeletons: `GameManager`, `ProgressionManager`, `QuestionBank`, `AudioManager`, `SaveManager` (empty/stub methods + signals wired). |
| Hr 2–3 | `ProgressionManager` full implementation (flat 1-grade demotion, doc 5) + throwaway test script. Verify promote/demote math in isolation before touching UI. |
| Hr 3–5 | `QuestionData` + generators for Grade 1 (Addition) and Grade 2 (Subtraction). Basic distractor logic + dedup. |
| Hr 5–7 | Game scene: placeholder question panel + 4 answer buttons (plain Godot `Button`s, no art yet), wire input (keyboard A/B/X/Y letters + controller face buttons; arrow keys highlight and Enter confirms), wire to `ProgressionManager.register_answer`. |
| Hr 7–8 | HUD: grade/score/timer/lives labels wired to live state. Basic 2-minute session timer countdown and 9-life pool (1 life lost per incorrect answer) → either triggers Game Over state. |
| Hr 8–9 | Lunch/break + buffer (do not skip breaks — jam burnout is real). |
| Hr 9–10 | Title screen (placeholder art, Press Start → starts session) and Game Over screen (placeholder, shows score/grade, Retry/Title buttons). |
| Hr 10–11 | Grade 3 (Multiplication + multi-digit add/sub) and Grade 4 (multi-digit multiplication, long division, fractions-like-denom, decimals) generators. |
| Hr 11–12 | Basic Geometry curated JSON bank (Grade 4) + loader. |
| **End of Day 1 checkpoint** | **You should be able to: launch, play through Grades 1→4 promotions/demotions, hit game over on timer expiry or on losing all 9 lives, see score.** Ugly art is fine. This is the MVP milestone. |

## Day 2 — Feel, Feedback, Polish, Submission
| Time | Task |
|---|---|
| Hr 0–1 | High score persistence (`SaveManager`): save/load JSON, show on Title + Game Over. |
| Hr 1–2 | Pause menu (Resume/Restart/Quit), wire Start button/Esc. |
| Hr 2–3 | Level-Up popup + Demotion popup (functional first: text + timer-based auto-dismiss; pause gameplay timer while shown). |
| Hr 3–5 | Cat sprite art pass (idle/happy/sad, even simple 2-frame) + AnimatedSprite2D wiring to correct/incorrect/promote/demote events. |
| Hr 5–6 | SFX pass: correct, incorrect, level-up, demotion, UI confirm at minimum (doc 8 MVP priority list). |
| Hr 6–7 | Answer button + panel art pass (9-slice frames, correct/incorrect flash states, input glyphs). |
| Hr 7–8 | Break/buffer. |
| Hr 8–9 | Music pass (title + gameplay loop) if time allows; otherwise skip — SFX matters more than music for feel. |
| Hr 9–10 | Controller testing pass on real Xbox controller: verify all screens navigable, no keyboard-only dead ends, pause/resume works mid-question. |
| Hr 10–11 | Bug bash: play 5+ full sessions end-to-end, fix crashes/soft-locks first, cosmetic issues second. |
| Hr 11–12 | Export build (Windows), write jam submission description, record short gameplay clip/gif, submit with buffer time before deadline. |

## Golden Rules
1. **Don't touch art/audio until the core loop works with placeholders.** Logic first, feel second.
2. **Timebox everything.** If a task blows its slot by more than ~50%, cut scope (drop to Won't-have) rather than extend — see doc 10 MoSCoW backlog for what to cut first.
3. **Commit working states frequently** (every checkpoint above is a good commit point) so you can always roll back to "last known playable."
4. **Test on the actual Xbox controller early** (end of Day 1 at latest), not just Day 2 — controller-specific bugs are cheaper to fix before UI is finalized.
