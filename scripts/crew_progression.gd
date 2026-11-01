extends RefCounted
## Cosmetic identity and rewards derived only from committed campaign results.
const HEROES = {
	"firefighter": {"name": "Maya", "trait": "Calm under pressure", "bio": "Maya keeps everyone steady, one safe step at a time.",
		"select": ["Easy does it. Let's make this safe.", "I'm here. We'll get everyone out.", "One clear path is all we need."],
		"victory": ["Everyone's home. That's what matters.", "A safe ending. A fresh start.", "We did this together."]},
	"engineer": {"name": "Theo", "trait": "Practical, quietly playful", "bio": "Theo sees a way forward wherever something needs fixing.",
		"select": ["Right tool, right place. Let's go.", "A little teamwork beats a bigger toolbox.", "Let's turn this problem around."],
		"victory": ["Good as new. Maybe a little better.", "That's another route back to normal.", "Best tool on the team? Each other."]},
	"ranger": {"name": "Nia", "trait": "Watchful and reassuring", "bio": "Nia spots trouble early and makes room for others to feel safe.",
		"select": ["I've got the crossing. Stay close.", "Clear heads, clear paths.", "Slow and steady. I'm watching ahead."],
		"victory": ["All clear. You can breathe now.", "Another quiet street. I like that.", "Safe passage, all the way home."]},
}
const STYLES = ["standard", "ribbon", "harbor", "captain", "floodworks"]
const LABELS = {"standard": "Field kit", "ribbon": "Rescue ribbon", "harbor": "Harbor colours", "captain": "Captain star", "floodworks": "Floodworks crest"}
const REQUIREMENTS = {"standard": "Always available", "ribbon": "Complete 1 mission", "harbor": "Complete 5 missions", "captain": "Complete 10 missions", "floodworks": "Complete trials 21–23"}
var path: String
var equipped := "standard"
var settings_saved := true
var _last: Dictionary = {}

func _init(file_path: String = "user://rescue_crew_v1.cfg") -> void:
	path = file_path
	var config := ConfigFile.new()
	if config.load(path) == OK:
		var choice: Variant = config.get_value("crew", "insignia", "standard")
		if choice is String and choice in STYLES:
			equipped = choice

static func unlocked(progress: RefCounted) -> Array[String]:
	var result: Array[String] = ["standard"]
	if progress.best.size() >= 1: result.append("ribbon")
	if progress.best.size() >= 5: result.append("harbor")
	if progress.best.size() >= 10: result.append("captain")
	if progress.is_complete("21") and progress.is_complete("22") and progress.is_complete("23"):
		result.append("floodworks")
	return result

func validate_equipped(progress: RefCounted) -> void:
	if equipped not in unlocked(progress): equipped = "standard"

func equip(style: String, progress: RefCounted) -> bool:
	if style not in unlocked(progress): return false
	equipped = style
	var config := ConfigFile.new()
	config.set_value("crew", "insignia", equipped)
	var temp := path + ".tmp"
	settings_saved = config.save(temp) == OK
	if settings_saved:
		settings_saved = DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), ProjectSettings.globalize_path(path)) == OK
	if not settings_saved: DirAccess.remove_absolute(ProjectSettings.globalize_path(temp))
	return settings_saved

func line(role: String, event: String) -> String:
	var choices: Array = HEROES[role][event]
	var key := role + event
	var index := randi_range(0, choices.size() - 1)
	if _last.has(key): index = (int(_last[key]) + randi_range(1, choices.size() - 1)) % choices.size()
	_last[key] = index
	return choices[index]
