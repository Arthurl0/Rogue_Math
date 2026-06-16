extends TextureButton
class_name Card
var val:int = 1:
	set(new_val):
		val = new_val
		_update_ui()
		
@onready var card_label: Label = $CardLabel

signal clique(carta: Card)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_update_ui()
	pressed.connect(_on_pressed)
	
func _update_ui() -> void:
	if card_label:
		card_label.text = str(val)

func _on_pressed() -> void:
	clique.emit(self)
	
