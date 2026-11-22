# Tests — Godot AI Methods

Testy jednostkowe i integracyjne napisane z użyciem [GUT (Godot Unit Testing)](https://github.com/bitwes/Gut).

## Struktura

```
Tests/
├── FSM/
│   ├── test_state.gd              # Bazowa klasa State (sygnał, metody stub)
│   ├── test_state_machine.gd      # StateMachine: inicjalizacja, tranzycje, delegacja
│   ├── test_enemy_idle.gd         # EnemyIdle: wander, próg → Follow
│   ├── test_enemy_follow.gd       # EnemyFollow: prędkość, próg → Idle / Attack
│   └── test_enemy_attack.gd       # EnemyAttack: null-safety, próg → Follow
│
├── Generation/
│   └── test_maze_generator.gd     # MazeGenerator: wymiary, granice, wartości, sygnał
│
├── Pathfinding/
│   └── test_pathfinding.gd        # pathfinding.gd: smoke test metod koordynatora
│
└── Demo/
    ├── test_procedural_generation.gd  # ProceduralSpawner: reguły, odległości, seed
    └── test_demo_scene.gd             # demo.gd: smoke test back-button
```

## Uruchamianie testów

### Przez panel GUT w edytorze
1. Otwórz **Project → Tools → GUT** (lub panel boczny).
2. Kliknij **Run All** lub wybierz konkretny katalog.

### Przez wiersz poleceń (headless)
```bash
godot --headless -s addons/gut/gut_cmdln.gd \
  -gdir=res://Tests/FSM \
  -gdir=res://Tests/Generation \
  -gdir=res://Tests/Pathfinding \
  -gdir=res://Tests/Demo \
  -gexit
```

Lub krócej, korzystając z `.gutconfig.json` w katalogu projektu:
```bash
godot --headless -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gexit
```

## Konwencje

| Element | Wartość |
|---|---|
| Prefiks pliku testu | `test_` |
| Prefiks metody testu | `test_` |
| Fixture przed każdym testem | `before_each()` |
| Autowolne node'y | `add_child_autofree(node)` |
| Obserwowanie sygnałów | `watch_signals(obj)` |
