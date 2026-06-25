extends Resource
class_name PowerupData

@export var name: String = "Powerup"
@export var shoot_speed: float = 0.6
@export var length: float = 5.0
@export var move_speed: float = 75.0
@export var texture: Texture2D
@export var health_change: int = 0
@export var shell_speed: float = 200.0
@export var shell_scale: float = 1.0
@export var shell_immune: bool = false
@export var fire_to_trigger = false
@export var use_timer = true
@export var damage_shooter = false
