extends Node

# Global enums and constants for the Dune RTS game
# This avoids circular dependencies between classes

enum Faction {
	ATREIDES,
	HARKONNEN,
	ORDOS,
	NEUTRAL
}

enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER
}

enum HarvesterState {
	IDLE,
	MOVING_TO_SPICE,
	COLLECTING_SPICE,
	MOVING_TO_REFINERY,
	UNLOADING_SPICE,
	RETURNING_TO_SPICE
}

# Game constants
const SPICE_COLLECTION_RATE: int = 25
const STARTING_SPICE: int = 1000