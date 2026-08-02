class_name UpgradeData
extends Resource

@export var upgrade_id: StringName
@export var title: String
@export_multiline var description: String
@export var amount: float
@export var secondary_value: float = 0.0
@export_enum("Common", "Rare", "Legendary") var rarity: int = 0
@export var max_level: int = 1
@export var unlock_level: int = 2
@export var healing_only: bool = false
@export var tags: Array[StringName] = []


func get_rarity_name() -> String:
	match rarity:
		1:
			return "RARE"
		2:
			return "LEGENDARY"
		_:
			return "COMMON"


func get_rarity_color() -> Color:
	match rarity:
		1:
			return Color("65bfff")
		2:
			return Color("ffb84f")
		_:
			return Color("8fffc2")
