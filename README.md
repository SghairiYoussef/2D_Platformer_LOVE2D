
# Game Documentation

## Introduction

This document provides an overview and documentation for the Love2D game implemented in Lua. The game includes basic functionalities for character movement, jumping, collisions, and a simple menu system.

## Table of Contents

1. [Requirements](#requirements)
2. [Installation](#installation)
3. [Game Overview](#game-overview)
    - [Player Controls](#player-controls)
4. [Code Structure](#code-structure)
5. [Functionality Overview](#functionality-overview)
    - [Player Movement](#player-movement)
    - [Jumping](#jumping)
    - [Collisions](#collisions)
    - [Menu System](#menu-system)
6. [Saving and Loading](#saving-and-loading)
7. [Additional Features](#additional-features)
8. [Contributing](#contributing)
9. [License](#license)

## Requirements

- Love2D framework installed on your system.

## Installation

1. Clone or download the game repository.
2. Open the project folder in a Love2D-compatible text editor or IDE.
3. Run the game by dragging the project folder onto the Love2D executable or using the command `love /path/to/project`.

## Game Overview

The game is a 2D platformer implemented in Love2D. The player controls a character that can move, jump, and interact with the environment.

### Player Controls

- **Movement:** Left and Right arrow keys.
- **Run:** Left Shift while moving.
- **Jump:** Spacebar.
- **Pause Menu:** Escape key.

## Code Structure

The code is organized into multiple sections:

- **Initialization:** Game setup and initialization of variables.
- **Physics Setup:** Configuration of the game's physics using the Windfield library.
- **Player Setup:** Definition of the player character and its collider.
- **Animation Setup:** Loading and configuration of character animations using the Anim8 library.
- **Menu Setup:** Initialization of buttons for the start menu.
- **Update Function:** Main game loop for updating game logic.
- **Draw Function:** Rendering of game elements.
- **Input Handling:** Functions for handling mouse and keyboard input.

## Functionality Overview

### Player Movement

The player can move left and right using the arrow keys. Holding the left shift key while moving activates a running state.

### Jumping

The player can jump by pressing the spacebar. The jump is limited to a certain height, and the player can perform multiple consecutive jumps.

### Collisions

Collision detection is implemented using the Windfield library. The player collides with the environment and walls.

### Menu System

A simple menu system is implemented for starting the game, saving progress, and exiting.

## Saving and Loading

The game includes basic functionality for saving and loading progress. The `saveGame` and `loadGame` functions handle this feature.

## Additional Features

- **Camera:** The game includes a basic camera system using the HUMP library for smooth following of the player.

## Contributing

Contributions to the project are welcome. Feel free to submit bug reports, feature requests, or pull requests.

## License

This game is open-source
