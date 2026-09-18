# 8. Sound Effect & Music List

## Implemented MVP Core
- `AudioManager` is an autoload that synthesizes the seven current chip cues at runtime, so the jam build has audible feedback without checked-in binary assets.
- `ProgressionManager.answer_registered` triggers `correct_answer` or `incorrect_answer`; `promoted` and `demoted` trigger the matching progression stingers. Retry, Restart, and Quit to Title call `ui_confirm`; Start Game begins silently. Pause calls `pause`; Resume calls `unpause`.
- The `SFX` bus is set to `-4 dB` beneath Master. Individual cue gains are deliberately restrained: confirm is quietest, incorrect/demotion are softer than correct/level-up, and level-up is the most prominent feedback cue.
- Current procedural cue peaks, before the SFX bus trim: `correct_answer` is `-23.1 dBFS` (`0.07` linear gain), `level_up` is `-26.5 dBFS` (`0.0475`), `demotion` is `-12.4 dBFS` (`0.24`), `incorrect_answer` is `-14.0 dBFS` (`0.20`), and `ui_confirm` is `-14.9 dBFS` (`0.18`). Correct answer is reduced by `6.0 dB` (half its prior runtime amplitude) and level-up by `12.0 dB` (one quarter of its prior runtime amplitude), without changing waveform, pitch, envelope, duration, player routing, or bus settings. After the shared `-4 dB` bus trim, they peak at roughly `-27.1 dBFS` and `-30.5 dBFS`, respectively, providing intentionally subtle positive and celebratory feedback over future music and ambience.
- Replace the generated tones with authored `.wav` assets later by changing `AudioManager.play_sfx()` to assign streams from `res://assets/audio/sfx/`; its public cue names stay the same.
- `AudioManager.play_music(name)` loads one loopable OGG track into its Music-bus player. Title music is disabled for now; Grades 1-4 use `kitten_theme.ogg`, Grades 5-8 use `bigcat_theme.ogg`, Grades 9-10 use `tiger_theme.ogg`, Grade 11 uses `satcat_theme.ogg`, and Grade 12 uses `final_level_theme.ogg`. Reaching Grade 13 in Standard Mode ends the session in victory and plays `victory_theme.ogg`; `nerdcat_theme.ogg` remains available for Grade 13 Practice Mode and future non-victory content.

| Sound | Trigger | Style Notes |
|---|---|---|
| `sfx_correct` | Correct answer selected | Bright, short chime/arpeggio (NES "coin"-like) |
| `sfx_incorrect` | Incorrect answer selected | Short buzzer/dud note, not too harsh |
| `sfx_life_lost` | A life is removed (plays alongside `sfx_incorrect` on every wrong answer) | Quick descending blip/heart-break sound, distinct timbre from `sfx_incorrect` |
| `sfx_ui_move` | Menu navigation (pause/game over button focus change) | Soft blip |
| `sfx_ui_confirm` | Button confirm/select | Slightly brighter blip than move |
| `sfx_ui_cancel` | Back/cancel | Low blip |
| `sfx_level_up` | Promotion triggered | Ascending fanfare, 1–2 sec |
| `sfx_demotion` | Demotion triggered | Short descending "sad trombone" style stinger |
| `sfx_pause` | Pause menu opens | 360 ms 25% pulse phrase, G5-C5-G5-C5; neutral and lower in gain than gameplay feedback |
| `sfx_unpause` | Pause menu closes | 360 ms 25% pulse phrase, G5-C5-G5-C5; neutral and lower in gain than gameplay feedback |
| `sfx_timer_warning` | Last 10 seconds of session (stretch) | Soft tick, increasing tempo |
| `sfx_game_over` | Session ends | Short descending jingle |
| `sfx_high_score` | New high score achieved on Game Over screen | Bright celebratory jingle, layered over/after game_over stinger |
| `music_gameplay` | Gameplay loop | Upbeat, slightly tense/energetic chiptune loop, ~30–60s seamless loop |
| `music_game_over` | Game Over screen (optional, can just use jingle + silence) | Low-key, reflective short loop or none |

## Implementation Notes
- Route all one-shot SFX through a small pool of `AudioStreamPlayer` nodes managed by `AudioManager` (e.g., 4–8 players round-robin) so rapid-fire correct/incorrect answers don't cut each other off.
- Use two dedicated `AudioStreamPlayer`s (or `AudioStreamPlayer` + bus) for music, with a `Bus Layout` split: `Master → Music`, `Master → SFX`, so pause menu volume sliders (stretch feature) can control them independently.
- Use the supplied **`.ogg`** files for music. `AudioManager` enables looping for imported OGG streams.
- If time-constrained: royalty-free/CC0 chiptune SFX packs (e.g., freesound.org, opengameart.org, jsfxr-generated sounds) are a legitimate and common jam shortcut — `jsfxr`/`sfxr`-style tools can generate all the short stingers above in minutes.
- MVP priority complete: `correct_answer`, `incorrect_answer`, `level_up`, `demotion`, and `ui_confirm`. `sfx_life_lost`, music, and remaining polish stingers remain deferred.
