extends CanvasLayer

signal chips_file_selected

func _ready() -> void:
    var err := $Control/OpenFileDialog.connect("file_selected", Callable(self, "file_selected"))
    if err != OK:
        push_error("Failed to connect OpenFileDialog.file_selected to self.file_selected")

func popup_open_file_dialog() -> void:
    $Control/OpenFileDialog.popup()

func file_selected(path: String) -> void:
    emit_signal("chips_file_selected", path)
