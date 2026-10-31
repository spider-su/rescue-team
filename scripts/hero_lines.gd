extends RefCounted
## Cosmetic variation only. Puzzle rules and saves never use randomness.
const LINES = {
	"water": ["Too much water! Let's turn the valve first.", "The engineer can drain this route at the valve.", "Flooded passage ahead. We need to drain it.", "Open the valve before we cross the water."],
	"bridge": ["This bridge needs the engineer's repair.", "We need a safe crossing. Engineer, you're up!", "Let's repair that broken bridge first.", "The engineer can fix this gap after the water drains."],
	"valve": ["We need the engineer at this valve.", "The engineer can turn that wheel.", "Ask the engineer to drain the passage.", "That's the valve. Engineer, can you open it?"],
	"fire": ["Can't walk through the fire! We need the firefighter.", "Too hot to cross. Let's put those flames out first.", "Fire ahead! The firefighter can clear it.", "That route is burning. Let's make it safe first."],
	"gate": ["We need to open the gate first!", "Gate's locked. Get the crate onto the blue switch.", "No way through yet. Let's power that gate.", "The blue switch opens this gate. Engineer, you're up!"],
	"infected": ["Infected ahead! We need the ranger.", "Let's have the ranger clear that passage.", "That way isn't safe. Ranger, bring the stun shield!", "Hold up! The ranger needs to contain them first."],
	"crate": ["That crate's in the way. We need the engineer.", "Let's ask the engineer to move that crate.", "Can't squeeze past that box. Engineer, you're up!", "Crate ahead! The engineer can push it aside."],
	"push": ["No room to push! Let's try another side.", "Something's blocking the crate. Clear its next tile first.", "That push won't work. Let's find a clear approach.", "We need space behind the crate before we push."],
	"wall": ["Can't walk through a wall! Let's find a passage.", "Solid wall ahead. Let's try another route.", "No opening here. We'll have to go around.", "That wall isn't going anywhere. Let's find a way around."],
	"rescuer": ["A teammate's in the way. Let's move them first.", "We need a little space! Move the other rescuer.", "That tile's taken. Let's reposition the crew.", "The passage is crowded. Let's move our teammate aside."],
	"route": ["I can't reach that spot yet. Let's clear a passage.", "No safe way through. Let's check the obstacles.", "We're cut off. Let's open a route first.", "That path is blocked. Let's try another approach."],
}
var _previous: Dictionary = {}

func next_line(reason: String) -> String:
	if not LINES.has(reason):
		return ""
	var choices: Array = LINES[reason]
	var index := randi_range(0, choices.size() - 1)
	if _previous.has(reason):
		index = (int(_previous[reason]) + randi_range(1, choices.size() - 1)) % choices.size()
	_previous[reason] = index
	return choices[index]
