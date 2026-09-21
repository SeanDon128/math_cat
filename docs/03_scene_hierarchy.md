# 3. Scene Hierarchy Recommendations

## Bootstrap
```
main.tscn (Node)
  - loads Title scene on _ready via GameManager.goto_scene()
```
Autoloads (`GameManager`, `ProgressionManager`, `QuestionBank`, `AudioManager`, `SaveManager`) live outside the scene tree as singletons — not shown below.

## Title Scene
```
Title (Control, full rect)
  Background (TextureRect - pixel bg)
  VBoxContainer (centered)
    Logo (TextureRect - "Math Cat" logo)
    StartGameButton (Button - green "Start Game")
    HighScoreTeaser (Label - "Best: 420 (Grade 4)")
    InputHintRow (HBoxContainer: keyboard icon, controller icon)
  AnimationPlayer (idle cat cameo)
  MusicPlayer (AudioStreamPlayer, title loop)
```

## Game Scene (core gameplay)
```
Game (Control)
  Background (ColorRect + synthwave_background.gdshader, full rect behind all gameplay; includes procedural grid and shooting stars)
  BackgroundEvolutionManager (Node, maps grade to stage and shooting-star intensity uniforms)
  Cat (CharacterCat.tscn instance)
    AnimatedSprite2D (idle/happy/sad/blink states)
  Content (MarginContainer)
    Layout (VBoxContainer)
      HeaderBar (PanelContainer)
        Header (HBoxContainer)
          GradeProgressPanel (upper left)
            GradeLabel
            CorrectProgress (label + 5 pixel pips)
            IncorrectProgress (label + 3 pixel pips)
          ScoreTimePanel (ScoreLabel + TimerLabel)
          HeartContainer (upper right, 9 pixel heart containers)
      QuestionPanel (PanelContainer)
        QuestionLabel (large, autowrapping, centered)
      Answers (Control, cross layout)
        AnswerButton.tscn x4 (choice value only)
        XboxFaceButtons (noninteractive central A/B/X/Y circular diamond)
  GameOverOverlay / PauseOverlay (hidden Control overlays)
  SfxPlayer (AudioStreamPlayer, gameplay one-shots; or route through AudioManager pool)
  MusicPlayer (AudioStreamPlayer, gameplay loop)
```

### AnswerButton.tscn (reusable component)
```
AnswerButton (Button, custom theme)
  MarginContainer
    ChoiceLabel (Label)
  FlashOverlay (ColorRect, alpha 0 — flashes green/red on selection via AnimationPlayer)

XboxFaceButtons (Control, mouse-ignore)
  Y / X / B / A (circular colored panels in Xbox face-button positions)
```

### LevelUpPopup.tscn / DemotionPopup.tscn (near-identical structure)
```
Popup (Control, full rect, semi-transparent backdrop)
  PanelContainer
    VBoxContainer
      Banner (Label - "Promoted to Grade 5!" / "Demoted to Grade 2")
      CatReaction (AnimatedSprite2D - happy/sad big pose)
      Hint (Label - "Get ready..." — auto-dismiss after timer, or "Press A to continue")
  AnimationPlayer (slide-in/scale-in, auto-close timer)
```

### PauseMenu.tscn
```
PauseMenu (Control, full rect, dim backdrop)
  PanelContainer
    VBoxContainer
      TitleLabel ("Paused")
      ResumeButton ("Resume")
      RestartButton
      QuitToTitleButton
      (stretch) SfxVolumeSlider / MusicVolumeSlider
```

## Game Over Scene
```
GameOver (Control, full rect)
  Background (TextureRect)
  VBoxContainer (centered)
    GameOverLabel
    FinalScoreLabel
    FinalGradeLabel
    StatsRow (HBoxContainer: correct count, incorrect count)
    HighScoreList (VBoxContainer of top-10 entries, current run highlighted if it placed)
    ButtonRow (HBoxContainer)
      RetryButton
      TitleScreenButton
```

## Reusable / Shared
```
CharacterCat.tscn
  AnimatedSprite2D (frames: idle, blink, happy, sad)
  AnimationPlayer (optional, for squash/stretch tweens on top of sprite frames)

HUD.tscn — shared instance pattern, instanced only inside Game.tscn
```

## Notes
- Keep Level-Up/Demotion/Pause as **child overlays within Game.tscn**, not separate scene-tree swaps — preserves gameplay/timer state and avoids re-instancing autoW connections.
- Use `%UniqueName` (scene-unique node names) in Godot 4 for stable references from scripts instead of long `NodePath`s.
- `AnswerButton` should expose a signal `answer_selected(button_index: int)` that `Game.gd` connects to once per question (or connect once and read `button_index` each time — prefer connect-once with a lookup array).
- `PixelMeterIcon` draws the heart and pip silhouettes procedurally as pixel grids, so filled and empty states do not need texture assets.
