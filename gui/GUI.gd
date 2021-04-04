extends CanvasLayer

signal chips_file_selected

func _ready() -> void:
    $Control/OpenFileDialog.connect("file_selected", self, "file_selected")

func popup_open_file_dialog() -> void:
    $Control/OpenFileDialog.popup()

func file_selected(path: String) -> void:
    emit_signal("chips_file_selected", path)
