extends Sprite2D

# ------------- [Exports] -------------
@export var rotation_speed: float = 2.0


# ------------- [Callbacks] -------------
func _process(delta: float) -> void:
	rotation += rotation_speed * delta
