@tool
extends EditorPlugin

const MENU = preload("context_menu.gd")

var plugin : EditorContextMenuPlugin


func _enable_plugin():
    pass


func _disable_plugin():
    pass


func _enter_tree():
    plugin = MENU.new()
    add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCENE_TREE, plugin)


func _exit_tree():
    remove_context_menu_plugin(plugin)
    plugin = null
