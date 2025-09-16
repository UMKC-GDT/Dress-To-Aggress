extends Resource
class_name ScenarioCard

@export var hub: FashionHub
@export var villain: Villain
@export var activity: IllicitActivity
@export var objective: AgencyObjective
@export var seed: int = 0
@export var tags: Array[String] = []

func summary() -> String:
	var hub_label := hub.display_label()
	var vil_label := villain.display_label()
	return "In %s, %s is orchestrating: %s.\nMission: %s." % [
		hub_label, vil_label, activity.display_label(), objective.display_label()
	]
