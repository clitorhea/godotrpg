# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a 2D RPG game built with Godot 4.4 using GDScript. The project features a top-down perspective with player movement, enemy AI, and combat mechanics.

## Project Structure

- `scenes/` - Godot scene files (.tscn)
  - `game.tscn` - Main game scene (uid://bb0r2ut2bddl0)
  - `village.tscn` - Village environment
  - `Player.tscn` / `Chacter.tscn` - Player character scenes
  - `Enemy.tscn` - Enemy character scene
- `scripts/` - GDScript files
  - `player.gd` - Main player controller with state machine (MOVE/ATTACK)
  - `player_optimized.gd` - Enhanced player controller with combat system
  - `enemy.gd` - Enemy AI with patrol/chase/attack states
- `assets/` - Game assets organized by type
  - Multiple sprite packs for characters, environments, and UI
  - Farm RPG, Tiny Swords, Village tilesets, and Brackeys platformer assets

## Core Game Systems

### Player Controller Architecture
- Uses CharacterBody2D with state machine pattern
- Two implementations: basic (`player.gd`) and optimized (`player_optimized.gd`)
- Movement: WASD input with acceleration/friction physics
- Combat: Space bar for attacks with directional animations
- Animation system with idle, walking, and attack states

### Enemy AI System
- State machine with PATROL, CHASE, ATTACK, DEAD states
- Detection range and attack range mechanics
- Patrol points system for movement when not chasing
- Health and damage system with visual feedback

### Input Configuration
- WASD for movement (up/down/left/right actions)
- Space bar for attack ("swing" action)
- Custom input deadzone of 0.2

### Display Settings
- Base resolution: 640x360
- Window override: 1920px width
- Viewport stretch mode with integer scaling
- Pixel-perfect rendering with default texture filter disabled

## Development Commands

This is a Godot project - use the Godot Editor for:
- Running the game: Press F5 or use Play button in editor
- Scene editing: Open .tscn files in Godot Editor
- Script editing: Can be done in Godot Editor or external editor

## Code Conventions

- Use snake_case for variables and functions
- Use PascalCase for enums and constants
- @export variables for editor-tweakable parameters
- @onready for node references
- Type hints encouraged (e.g., `var speed: float = 250.0`)
- State machines for complex behaviors
- Node groups for organization (enemies added to "enemies" group)

## Key Node Paths and References
- Player node referenced as `%knight` in enemy scripts
- AnimatedSprite2D nodes for character animations
- Camera2D attached to player for following
- Area2D/CollisionShape2D for attack detection ranges
