extends Node
class_name SelectionManager

## Selection Management System
##
## Single Responsibility: Handle unit/building selection logic with multi-select and box selection support
## 
## This manager handles all selection operations for units and buildings, providing a clean API
## for single selection, multi-selection, and box selection. It maintains separation between
## unit and building selections and emits events for UI updates.
##
## Usage Example:
## [codeblock]
## var sm = SelectionManager.new()
## sm.player_faction = GlobalEnums.Faction.ATREIDES
## sm.select_unit(my_unit, false)  # Single select
## sm.select_units_in_rect(Rect2(0, 0, 100, 100), true)  # Box select
## var info = sm.get_selection_info()  # Get selection details
## [/codeblock]

## Emitted when selection changes (units added/removed, building selected/deselected)
## @param selected_objects: Array containing all currently selected units and buildings
signal selection_changed(selected_objects: Array)

## Emitted when a unit is added to the selection
## @param unit: The unit that was selected
signal unit_selected(unit)

## Emitted when a unit is removed from the selection
## @param unit: The unit that was deselected
signal unit_deselected(unit)

## Emitted when a building is selected (only one building can be selected at a time)
## @param building: The building that was selected
signal building_selected(building)

## Emitted when a building is deselected
## @param building: The building that was deselected
signal building_deselected(building)

## Array of currently selected units (only units belonging to player_faction)
## Units are added/removed through select_unit/deselect_unit methods
var selected_units: Array[Unit] = []

## Currently selected building (only one building can be selected at a time)
## Set to null when no building is selected
var selected_building: Building = null

## The faction that the player controls
## Only units/buildings of this faction can be selected
var player_faction: GlobalEnums.Faction = GlobalEnums.Faction.ATREIDES

## Select a unit (if it belongs to player faction)
## @param unit: The unit to select
## @param multi_select: If false, clears all previous selections first; if true, adds to existing selection
## @return: true if unit was successfully selected, false if unit belongs to enemy faction or already selected
##
## Side Effects:
## - Updates unit's visual selection state
## - Emits unit_selected and selection_changed signals
## - If multi_select is false, clears all previous selections
##
## Example:
## [codeblock]
## # Single select (clears previous selection)
## selection_manager.select_unit(my_tank, false)
## 
## # Multi-select (adds to existing selection)
## selection_manager.select_unit(my_infantry, true)
## [/codeblock]
func select_unit(unit: Unit, multi_select: bool = false):
	if unit.faction != player_faction:
		return false
	
	if not multi_select:
		clear_all_selections()
	
	if unit not in selected_units:
		selected_units.append(unit)
		unit.set_selected(true)
		unit_selected.emit(unit)
		selection_changed.emit(get_all_selected())
		return true
	
	return false

## Remove a unit from the selection
## @param unit: The unit to deselect
##
## Side Effects:
## - Updates unit's visual selection state
## - Emits unit_deselected and selection_changed signals
##
## Example:
## [codeblock]
## selection_manager.deselect_unit(my_tank)
## [/codeblock]
func deselect_unit(unit: Unit):
	if unit in selected_units:
		selected_units.erase(unit)
		unit.set_selected(false)
		unit_deselected.emit(unit)
		selection_changed.emit(get_all_selected())

## Box selection - select all player units within a rectangle
## @param world_rect: Rectangle in world coordinates to select units within
## @param multi_select: If false, clears previous unit selection; if true, adds to existing selection
## @return: Number of units that were successfully selected
##
## This method implements box selection functionality by checking all units in the game
## and selecting those that belong to the player faction and are within the specified rectangle.
##
## Example:
## [codeblock]
## # Select all units in a 200x200 area
## var rect = Rect2(Vector2(100, 100), Vector2(200, 200))
## var count = selection_manager.select_units_in_rect(rect, true)
## print("Selected %d units" % count)
## [/codeblock]
func select_units_in_rect(world_rect: Rect2, multi_select: bool = false):
	if not multi_select:
		clear_unit_selection()
	
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if not game_manager:
		return
	
	var selected_count = 0
	for unit in game_manager.all_units:
		if unit.faction == player_faction and world_rect.has_point(unit.global_position):
			if select_unit(unit, true):
				selected_count += 1
	
	return selected_count

## Select a building (only one building can be selected at a time)
## @param building: The building to select
## @return: true if building was successfully selected, false if building belongs to enemy faction
##
## Side Effects:
## - Clears all previous selections (units and buildings)
## - Updates building's visual selection state
## - Emits building_selected and selection_changed signals
##
## Note: Only one building can be selected at a time, unlike units which support multi-selection
##
## Example:
## [codeblock]
## selection_manager.select_building(my_barracks)
## [/codeblock]
func select_building(building: Building):
	if building.faction != player_faction:
		return false
	
	clear_all_selections()
	selected_building = building
	building.set_selected(true)
	building_selected.emit(building)
	selection_changed.emit(get_all_selected())
	return true

## Deselect the currently selected building
##
## Side Effects:
## - Updates building's visual selection state
## - Emits building_deselected and selection_changed signals
## - Sets selected_building to null
##
## Example:
## [codeblock]
## selection_manager.deselect_building()
## [/codeblock]
func deselect_building():
	if selected_building:
		var old_building = selected_building
		selected_building = null
		old_building.set_selected(false)
		building_deselected.emit(old_building)
		selection_changed.emit(get_all_selected())

## Clear all selected units (keeps building selection)
##
## Side Effects:
## - Deselects all units and updates their visual states
## - Emits unit_deselected and selection_changed signals for each unit
##
## Example:
## [codeblock]
## selection_manager.clear_unit_selection()
## [/codeblock]
func clear_unit_selection():
	var units_to_deselect = selected_units.duplicate()
	for unit in units_to_deselect:
		deselect_unit(unit)

## Clear all selections (both units and buildings)
##
## Side Effects:
## - Deselects all units and the selected building
## - Updates all visual selection states
## - Emits appropriate deselection and selection_changed signals
##
## Example:
## [codeblock]
## selection_manager.clear_all_selections()
## [/codeblock]
func clear_all_selections():
	clear_unit_selection()
	deselect_building()

## Get array of currently selected units
## @return: Array of selected Unit objects (empty if no units selected)
##
## Example:
## [codeblock]
## var units = selection_manager.get_selected_units()
## for unit in units:
##     print("Selected: %s" % unit.unit_name)
## [/codeblock]
func get_selected_units() -> Array[Unit]:
	return selected_units

## Get the currently selected building
## @return: Selected Building object, or null if no building is selected
##
## Example:
## [codeblock]
## var building = selection_manager.get_selected_building()
## if building:
##     print("Selected building: %s" % building.building_name)
## [/codeblock]
func get_selected_building() -> Building:
	return selected_building

## Get array containing all selected objects (units and buildings)
## @return: Array containing selected units and building (if any)
##
## Example:
## [codeblock]
## var all_selections = selection_manager.get_all_selected()
## print("Total selected: %d" % all_selections.size())
## [/codeblock]
func get_all_selected() -> Array:
	var all_selected: Array = []
	all_selected.append_array(selected_units)
	if selected_building:
		all_selected.append(selected_building)
	return all_selected

## Check if anything is currently selected
## @return: true if any units or buildings are selected, false otherwise
##
## Example:
## [codeblock]
## if selection_manager.has_selection():
##     print("Something is selected")
## [/codeblock]
func has_selection() -> bool:
	return selected_units.size() > 0 or selected_building != null

## Get detailed information about current selection for UI display
## @return: Dictionary containing selection statistics and details
##
## Returns:
## [codeblock]
## {
##     "unit_count": int,           # Number of selected units
##     "has_building": bool,        # Whether a building is selected
##     "unit_types": Dictionary,    # Unit type -> count mapping
##     "total_health": Dictionary   # Current/max health info
## }
## [/codeblock]
##
## Example:
## [codeblock]
## var info = selection_manager.get_selection_info()
## print("Selected %d units" % info["unit_count"])
## if info["has_building"]:
##     print("Building selected")
## [/codeblock]
func get_selection_info() -> Dictionary:
	return {
		"unit_count": selected_units.size(),
		"has_building": selected_building != null,
		"unit_types": get_selected_unit_types(),
		"total_health": get_total_health()
	}

## Get count of each unit type in current selection
## @return: Dictionary mapping unit type names to their counts
##
## Example:
## [codeblock]
## var types = selection_manager.get_selected_unit_types()
## # types might be: {"Tank": 3, "Infantry": 5}
## for type_name in types:
##     print("%s: %d" % [type_name, types[type_name]])
## [/codeblock]
func get_selected_unit_types() -> Dictionary:
	var types = {}
	for unit in selected_units:
		var type_name = unit.unit_name
		if not types.has(type_name):
			types[type_name] = 0
		types[type_name] += 1
	return types

## Calculate total health statistics for all selected units
## @return: Dictionary containing health information
##
## Returns:
## [codeblock]
## {
##     "current": int,     # Sum of current health of all selected units
##     "max": int,         # Sum of max health of all selected units
##     "percentage": float # Health percentage (0-100)
## }
## [/codeblock]
##
## Example:
## [codeblock]
## var health = selection_manager.get_total_health()
## print("Group health: %d/%d (%.1f%%)" % [health["current"], health["max"], health["percentage"]])
## [/codeblock]
func get_total_health() -> Dictionary:
	var total_current = 0
	var total_max = 0
	
	for unit in selected_units:
		total_current += unit.current_health
		total_max += unit.max_health
	
	return {
		"current": total_current,
		"max": total_max,
		"percentage": (float(total_current) / float(total_max) * 100.0) if total_max > 0 else 0
	}
