extends Node
class_name CommandManager

## Command Pattern Implementation for RTS Actions
##
## Single Responsibility: Execute and manage game commands using the Command Pattern
## 
## This manager implements the Command Pattern to encapsulate all game actions (movement, 
## combat, production) as command objects. This provides a clean, extensible architecture
## for handling player input, AI actions, and potentially undo/redo functionality.
##
## Usage Example:
## [codeblock]
## var cm = CommandManager.new()
## # Direct command execution
## var move_cmd = CommandManager.MoveCommand.new(units, Vector2(500, 300))
## cm.execute_command(move_cmd)
## 
## # Convenience methods
## cm.move_units(selected_units, mouse_position)
## cm.attack_with_units(my_tanks, enemy_unit)
## [/codeblock]

## Emitted when a command finishes execution successfully
## @param command_name: Name of the command that was executed (e.g., "move", "attack")
## @param success: Always true for this signal (false commands use command_failed)
signal command_executed(command_name: String, success: bool)

## Emitted when a command fails to execute or cannot be executed
## @param command_name: Name of the command that failed
## @param reason: Human-readable explanation of why the command failed
signal command_failed(command_name: String, reason: String)

## Command history for potential undo/redo functionality (future feature)
## Stores recently executed commands for possible reversal
var command_history: Array = []

## Maximum number of commands to keep in history to prevent memory growth
var max_history_size: int = 100

## Base Command Interface
##
## All commands inherit from this class and must implement execute() method.
## Commands encapsulate an action with its target objects and parameters.
class Command:
	## Human-readable name for this command type (e.g., "move", "attack", "produce_unit")
	var command_name: String
	
	## Array of game objects this command will operate on (units, buildings, etc.)
	var target_objects: Array
	
	## Additional parameters required for command execution (positions, target units, etc.)
	var parameters: Dictionary
	
	## Constructor for command objects
	## @param name: Human-readable command identifier
	## @param targets: Array of objects this command will operate on  
	## @param params: Dictionary of additional parameters needed for execution
	func _init(name: String, targets: Array = [], params: Dictionary = {}):
		command_name = name
		target_objects = targets
		parameters = params
	
	## Execute the command action - MUST be overridden in subclasses
	## @return: true if command executed successfully, false otherwise
	func execute() -> bool:
		return false  # Override in subclasses
	
	## Check if command can currently be executed - Override in subclasses for validation
	## @return: true if command is valid and can execute, false otherwise
	func can_execute() -> bool:
		return true  # Override in subclasses
	
	## Get human-readable reason why command cannot execute - Override in subclasses
	## @return: String explaining why can_execute() returned false
	func get_failure_reason() -> String:
		return "Command cannot be executed"

## Movement Command - Move units to a target position
##
## Commands one or more units to move to a specific world position.
## Units will pathfind to the target location.
##
## Usage Example:
## [codeblock]
## var move_cmd = CommandManager.MoveCommand.new([tank1, tank2], Vector2(500, 300))
## command_manager.execute_command(move_cmd)
## [/codeblock]
class MoveCommand extends Command:
	## Constructor for movement command
	## @param units: Array of Unit objects to move
	## @param target_pos: World position (Vector2) to move units to
	func _init(units: Array[Unit], target_pos: Vector2):
		super._init("move", units, {"target_position": target_pos})
	
	## Validate that command has units and a target position
	## @return: true if at least one unit and target position are specified
	func can_execute() -> bool:
		return target_objects.size() > 0 and parameters.has("target_position")
	
	## Execute movement command by calling move_to() on each unit
	## @return: true if command was processed (individual units may still fail pathfinding)
	func execute() -> bool:
		if not can_execute():
			return false
		
		var target_pos = parameters["target_position"]
		for unit in target_objects:
			if unit and is_instance_valid(unit):
				unit.move_to(target_pos)
		
		return true

## Attack Command - Command units to attack a target
##
## Commands one or more units to attack a specific enemy unit.
## Units will move into range and engage the target.
##
## Usage Example:
## [codeblock]
## var attack_cmd = CommandManager.AttackCommand.new([tank1, tank2], enemy_unit)
## command_manager.execute_command(attack_cmd)
## [/codeblock]
class AttackCommand extends Command:
	## Constructor for attack command
	## @param units: Array of Unit objects to issue attack orders to
	## @param target_unit: Enemy Unit object to attack
	func _init(units: Array[Unit], target_unit: Unit):
		super._init("attack", units, {"target": target_unit})
	
	## Validate that command has units and a valid target
	## @return: true if at least one unit and valid target are specified
	func can_execute() -> bool:
		return target_objects.size() > 0 and parameters.has("target") and is_instance_valid(parameters["target"])
	
	## Execute attack command by calling attack_unit() on each unit
	## @return: true if command was processed (units will handle range and combat individually)
	func execute() -> bool:
		if not can_execute():
			return false
		
		var target = parameters["target"]
		for unit in target_objects:
			if unit and is_instance_valid(unit):
				unit.attack_unit(target)
		
		return true

## Production Command - Command a building to produce a unit
##
## Commands a production building (barracks, factory, etc.) to begin
## producing a specific unit type. Handles resource costs and queue management.
##
## Usage Example:
## [codeblock]
## var produce_cmd = CommandManager.ProduceUnitCommand.new(my_barracks, "infantry")
## command_manager.execute_command(produce_cmd)
## [/codeblock]
class ProduceUnitCommand extends Command:
	## Constructor for unit production command
	## @param building: Building object capable of producing units
	## @param unit_type: String identifier of unit type to produce (e.g., "tank", "infantry")
	func _init(building: Building, unit_type: String):
		super._init("produce_unit", [building], {"unit_type": unit_type})
	
	## Validate building can produce the requested unit type
	## @return: true if building exists and can produce the specified unit
	func can_execute() -> bool:
		if target_objects.size() != 1 or not parameters.has("unit_type"):
			return false
		
		var building = target_objects[0]
		var unit_type = parameters["unit_type"]
		
		return building.has_method("can_produce_unit") and building.can_produce_unit(unit_type)
	
	## Execute production command by calling produce_unit() on the building
	## @return: true if production was successfully started (building handles resources/queue)
	func execute() -> bool:
		if not can_execute():
			return false
		
		var building = target_objects[0]
		var unit_type = parameters["unit_type"]
		
		return building.produce_unit(unit_type)

## Stop Command - Cancel all unit actions
##
## Commands one or more units to stop their current actions (movement, combat).
## Useful for emergency stops or canceling accidental orders.
##
## Usage Example:
## [codeblock]
## var stop_cmd = CommandManager.StopCommand.new([tank1, tank2])
## command_manager.execute_command(stop_cmd)
## [/codeblock]
class StopCommand extends Command:
	## Constructor for stop command
	## @param units: Array of Unit objects to stop
	func _init(units: Array[Unit]):
		super._init("stop", units)
	
	## Execute stop command by clearing movement and combat targets
	## @return: Always true - stop commands cannot fail
	func execute() -> bool:
		for unit in target_objects:
			if unit and is_instance_valid(unit):
				unit.movement_path.clear()
				unit.is_moving = false
				unit.attack_target = null
		
		return true

## Main command execution method - validates and executes any command
## @param command: Command object to execute
## @return: true if command was successfully executed, false if validation or execution failed
##
## This is the central method for all command execution. It handles validation,
## execution, history tracking, and signal emission.
##
## Side Effects:
## - Emits command_executed signal on success
## - Emits command_failed signal on failure
## - Adds successful commands to history
##
## Example:
## [codeblock]
## var cmd = CommandManager.MoveCommand.new(units, target_pos)
## if command_manager.execute_command(cmd):
##     print("Units are moving")
## [/codeblock]
func execute_command(command: Command) -> bool:
	if not command.can_execute():
		command_failed.emit(command.command_name, command.get_failure_reason())
		return false
	
	var success = command.execute()
	
	if success:
		add_to_history(command)
		command_executed.emit(command.command_name, true)
	else:
		command_failed.emit(command.command_name, "Execution failed")
	
	return success

## Add a successfully executed command to the history
## @param command: Command object to store in history
##
## Maintains a fixed-size history buffer for potential undo functionality.
## Automatically removes oldest commands when history exceeds max_history_size.
func add_to_history(command: Command):
	command_history.append(command)
	if command_history.size() > max_history_size:
		command_history.pop_front()

## Convenience method for unit movement
## @param units: Array of Unit objects to move
## @param target_position: World position (Vector2) to move units to
## @return: true if movement command was successfully executed
##
## This is a shorthand for creating and executing a MoveCommand.
##
## Example:
## [codeblock]
## var selected = selection_manager.get_selected_units()
## command_manager.move_units(selected, mouse_world_position)
## [/codeblock]
func move_units(units: Array[Unit], target_position: Vector2) -> bool:
	var command = MoveCommand.new(units, target_position)
	return execute_command(command)

## Convenience method for unit combat
## @param units: Array of Unit objects to issue attack orders to
## @param target: Enemy Unit object to attack
## @return: true if attack command was successfully executed
##
## Example:
## [codeblock]
## var tanks = selection_manager.get_selected_units()
## command_manager.attack_with_units(tanks, enemy_harvester)
## [/codeblock]
func attack_with_units(units: Array[Unit], target: Unit) -> bool:
	var command = AttackCommand.new(units, target)
	return execute_command(command)

## Convenience method for unit production
## @param building: Building object capable of producing units
## @param unit_type: String identifier of unit type to produce
## @return: true if production command was successfully executed
##
## Example:
## [codeblock]
## var barracks = selection_manager.get_selected_building()
## command_manager.produce_unit(barracks, "infantry")
## [/codeblock]
func produce_unit(building: Building, unit_type: String) -> bool:
	var command = ProduceUnitCommand.new(building, unit_type)
	return execute_command(command)

## Convenience method for stopping unit actions
## @param units: Array of Unit objects to stop
## @return: true if stop command was successfully executed (always succeeds)
##
## Example:
## [codeblock]
## var selected = selection_manager.get_selected_units()
## command_manager.stop_units(selected)  # Emergency stop
## [/codeblock]
func stop_units(units: Array[Unit]) -> bool:
	var command = StopCommand.new(units)
	return execute_command(command)