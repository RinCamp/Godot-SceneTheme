extends EditorContextMenuPlugin

const ICON = preload("icon/blender_icon_node_texture.svg")
const DIALOG = preload("scene/dialog.tscn")

var popup : Window


func _popup_menu(paths: PackedStringArray):
    var scene_root = EditorInterface.get_edited_scene_root()
    if not scene_root.scene_file_path:
        return

    var selected_nodes = EditorInterface.get_selection().get_selected_nodes()
    if not selected_nodes or selected_nodes.size() > 1 or selected_nodes.front() is not Control:
        return

    add_context_menu_item("SceneTheme", _on_popup_menu_pressed, ICON)


func _on_popup_menu_pressed(_paths: PackedStringArray):
    if popup:
        popup.queue_free()

    popup = DIALOG.instantiate()
    EditorInterface.popup_dialog_centered(popup)
    await popup.visibility_changed
    popup.queue_free()
