# Dune RTS Recreation

A faithful recreation of the classic Dune 2 RTS game built with Godot 4.

## 🎮 Current Features (Week 1 Prototype)

- **Unit Selection & Movement**: Click to select units, right-click to move
- **Spice Collection**: Harvesters automatically collect spice from deposits
- **Camera Controls**: WASD keys or mouse edge scrolling
- **Basic Combat**: Tanks can attack enemy units
- **Resource Management**: Spice counter and collection system
- **Three Factions**: Atreides (Blue), Harkonnen (Red), Ordos (Green)

## 🚀 Controls

- **Left Click**: Select units
- **Right Click**: Move selected units or attack enemies
- **WASD**: Move camera
- **Ctrl+Click**: Add units to selection
- **A**: Select all units
- **S**: Stop selected units
- **ESC**: Deselect all

## 🛠️ Development

**Engine**: Godot 4.2+  
**Language**: GDScript  
**Target Platforms**: Windows, Linux, macOS  

### Running the Game

1. Install Godot 4.2 or later
2. Open `project.godot` in Godot
3. Press F5 to run

### Current Status

This is a Week 1 prototype featuring core gameplay mechanics. The game uses placeholder graphics (colored rectangles) but includes functional gameplay systems.

**Implemented:**
- [x] Basic unit movement and selection
- [x] Spice harvesting system
- [x] Combat mechanics
- [x] Camera controls
- [x] Resource management
- [x] Building placement (refinery)

**Coming Next:**
- [ ] Advanced AI opponent
- [ ] Complete tech trees
- [ ] Mission system
- [ ] Enhanced graphics
- [ ] Sound effects

## 📁 Project Structure

```
├── scenes/           # Godot scene files
│   ├── units/       # Unit scene templates
│   └── buildings/   # Building scene templates
├── scripts/         # GDScript source code
├── assets/          # Game assets (placeholder graphics)
├── data/            # JSON configuration files
└── docs/            # Documentation
```

## 🎯 Game Features

### Units
- **Harvester**: Collects spice from deposits
- **Tank**: Basic combat unit
- **Special Units**: Faction-specific units (planned)

### Buildings
- **Refinery**: Processes collected spice
- **Construction Yard**: Base building (planned)
- **Factories**: Unit production (planned)

### Resources
- **Spice**: Primary resource for construction and production
- Deposits scattered across the map
- Finite resource requiring expansion

## 🤝 Contributing

This is a personal recreation project. Feedback and suggestions welcome!

## 📜 License

This project is for educational/recreational purposes. All assets are original or from free/open sources.

---

*Built with ❤️ and Godot 4*