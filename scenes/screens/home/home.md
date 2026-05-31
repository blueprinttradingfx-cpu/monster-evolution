Below is a **Godot 4 `.tscn` scene equivalent** of your HTML UI, structured so you can directly recreate it in the editor.

This is not a literal file export (Godot scenes are normally editor-generated), but it is a **faithful node tree blueprint + ready-to-recreate structure**.

---

# 🎮 Home Scene (Godot 4) — `Home.tscn`

## Root

```text
Home (Control)
anchors preset: Full Rect
```

---

# 1. Top App Bar

```text
TopAppBar (PanelContainer)
anchors: Top Wide
custom minimum size: (0, 72)
theme overrides: border bottom = 4px
```

### Children:

```text
HBoxContainer
├── LeftGroup (HBoxContainer)
│   ├── Icon (TextureRect or Label)
│   └── Title (Label)
│
└── CurrencyGroup (PanelContainer)
    └── HBoxContainer
        ├── Coins (HBoxContainer)
        │   ├── CoinsLabel (Label)
        │   └── CoinIcon (TextureRect)
        │
        ├── Separator (ColorRect 1px width)
        │
        └── Eggs (HBoxContainer)
            ├── EggsLabel (Label)
            └── EggIcon (TextureRect)
```

---

# 2. Main Layout

```text
Main (VBoxContainer)
anchors: Center
custom minimum size: (420, 0)
alignment: center
```

Spacing ≈ 24–32px

---

# 3. Creature Section

```text
CreatureSection (VBoxContainer)
```

### Creature Visual Stack

```text
CreatureWrapper (Control)
custom minimum size: (260, 260)
```

### Inside:

```text
└── Glow (ColorRect)
    size: full
    color: purple with alpha ~0.2
    (optional: CanvasItem shader blur)

└── Creature (TextureRect)
    stretch mode: KEEP_ASPECT_CENTERED
```

### Animation (floating)

Attach script:

```gdscript
extends Control

@onready var creature = $Creature

func _ready():
    var t = create_tween().set_loops()
    t.tween_property(creature, "position:y", -12, 2.0)
    t.tween_property(creature, "position:y", 0, 2.0)
```

---

## Progress Section

```text
ProgressSection (VBoxContainer)
```

### Header Row:

```text
HBoxContainer
├── Label (Evolution Progress)
└── Label (LVL 4 · 7/10)
```

### Progress Bar:

```text
ProgressBar (TextureProgressBar)
min: 0
max: 10
value: 7
```

Theme:

* Fill: green → purple gradient
* Border: 2px dark outline
* Height: ~24px

---

# 4. Action Buttons Section

```text
ActionButtons (VBoxContainer)
```

---

## PLAY Button (Primary CTA)

```text
PlayButton (Button)
custom minimum size: (0, 88)
```

### Internal layout:

```text
HBoxContainer
├── Icon (TextureRect)
└── VBoxContainer
    ├── Title Label (PLAY)
    └── Subtitle Label (Find matches & level up!)
```

Style:

* Background: purple (#6b38d4)
* Border: 2px dark
* Press animation: move down 4px

---

## Grid Buttons

```text
GridContainer
columns: 2
```

### MERGE

```text
MergeButton (Button)
├── Icon
└── Label (MERGE)
```

Style:

* green container
* slight shadow offset

---

### COLLECTION

```text
CollectionButton (Button)
├── Icon
└── Label (COLLECTION)
```

Style:

* light surface
* purple accent text

---

# 5. Daily Quest Card

```text
DailyQuestCard (PanelContainer)
```

### Layout:

```text
HBoxContainer
├── IconBox (Panel)
│   └── Icon
└── VBoxContainer
    ├── Title (Daily Quest)
    └── Description text
```

Style:

* dashed border (simulate via StyleBox or TextureBorder workaround)
* light background
* slight rounded corners

---

# 6. Bottom Navigation Bar

```text
BottomNav (PanelContainer)
anchors: bottom wide
```

### Inside:

```text
HBoxContainer
alignment: space_evenly
```

Tabs:

---

## PLAY (Active)

```text
PlayTab (Button)
└── VBoxContainer
    ├── Icon
    └── Label
```

Style:

* filled purple container
* lifted position (-4px)
* active state glow

---

## MERGE

```text
MergeTab (Button)
```

---

## COLLECTION

```text
CollectionTab (Button)
```

---

## SHOP

```text
ShopTab (Button)
```

---

# 7. Theme Setup (Critical)

Create:

```text
Theme.tres
```

Define:

## Colors

* Primary: #6b38d4
* Secondary: #006c49
* Background: #f8f9fa
* Surface: #ffffff
* Outline: #2D2D2D

---

## Button Styles

### Normal

* StyleBoxFlat
* corner_radius: 12
* border_width: 2

### Pressed

* offset: y = 4px
* shadow removed

---

## Typography

Map:

| HTML        | Godot Label Font |
| ----------- | ---------------- |
| display-lg  | Title            |
| headline-sm | Button text      |
| body-md     | subtitles        |

Use:

* `Plus Jakarta Sans`
* `Be Vietnam Pro`

---

# 8. Script Hooks (minimal required)

Attach to Home root:

```gdscript
extends Control

func _ready():
    $TopAppBar.connect("gui_input", _on_topbar_click)
```

Currency click:

```gdscript
func _on_topbar_click(event):
    if event is InputEventMouseButton and event.pressed:
        print("Currency clicked")
```

---

# 9. What you now effectively have

This conversion gives you:

* Fully native Godot UI (no HTML dependency)
* Responsive container-based layout
* Theme-driven design system equivalent to Tailwind
* Animation parity via Tween
* Mobile-ready structure (important for your use case)

---

# If you want next step (recommended)

I can extend this into:

### 1. Fully working Godot project structure

* scenes/
* scripts/
* theme/
* assets/

### 2. Exact Theme.tres file (copy-paste ready)

### 3. Mobile optimization layer (safe-area, scaling, touch targets)

Just tell me.
