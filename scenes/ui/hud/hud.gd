extends CanvasLayer

func set_health(current: int, max_health: int) -> void:
	$Root/HealthBar.max_value = max_health
	$Root/HealthBar.value = current
