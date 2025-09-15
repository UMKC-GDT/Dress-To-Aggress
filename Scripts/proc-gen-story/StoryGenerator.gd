extends Node
class_name ScenarioGenerator

# Point this at YOUR root data folder (from your screenshot):
@export var data_root := "res://Assets/Resources/proc-gen-story-res/"

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()

func generate(seed: int = 0) -> ScenarioCard:
	if seed != 0:
		_rng.seed = seed
	else:
		_rng.randomize()

	var hubs := _load_all_in_folder(data_root + "hubs")
	var villains := _load_all_in_folder(data_root + "villains")
	var activities := _load_all_in_folder(data_root + "illicit_activities")
	var objectives := _load_all_in_folder(data_root + "agency_objectives")

	assert(hubs.size() > 0, "No hubs found in %s/hubs" % data_root)
	assert(villains.size() > 0, "No villains found in %s/villains" % data_root)
	assert(activities.size() > 0, "No activities found in %s/activities" % data_root)
	assert(objectives.size() > 0, "No objectives found in %s/objectives" % data_root)

	var card := ScenarioCard.new()
	card.hub = _weighted_pick(hubs)
	card.villain = _weighted_pick(villains)
	card.activity = _weighted_pick(activities)
	card.objective = _weighted_pick(objectives)
	card.seed = seed
	return card

func _load_all_in_folder(path: String) -> Array:
	var out: Array = []

	# OPEN the res:// path directly; don't use dir_exists_absolute on res://
	var dir := DirAccess.open(path)
	if dir == null:
		push_warning("Folder not found or couldn't open: %s" % path)
		return out

	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name == "":
			break
		if dir.current_is_dir():
			continue
		if file_name.ends_with(".tres"):
			var res_path := "%s/%s" % [path, file_name]
			var res := ResourceLoader.load(res_path)
			if res == null:
				push_warning("Failed to load: %s" % res_path)
			else:
				out.append(res)
	dir.list_dir_end()

	print("Loaded %d resources from %s" % [out.size(), path])
	return out

func _weighted_pick(items: Array) -> Resource:
	var total := 0.0
	for i in items:
		total += _get_weight(i)
	var r := _rng.randf() * total
	for i in items:
		r -= _get_weight(i)
		if r <= 0.0:
			return i
	return items.back()

func _get_weight(item: Resource) -> float:
	if item == null:
		return 1.0
	if item is FashionHub:
		return (item as FashionHub).weight
	if item is Villain:
		return (item as Villain).weight
	if item is IllicitActivity:
		return (item as IllicitActivity).weight
	if item is AgencyObjective:
		return (item as AgencyObjective).weight
	return 1.0
