@tool
extends Control

const CLASS_PREFIX = "SceneTheme"

@warning_ignore("unused_private_class_variable")
@export_tool_button("Build Theme") var _tool = _run

# 加载/重载场景时自动构建
@export var auto_build : bool = false
# 主题资源名称, 为空时使用小写节点名
@export var res_name : String
# 从所选节点向下遍历获取符合此前缀的节点, 不包含其它场景的节点
@export var node_prefix : String = "TTV_"
# 保存时的主题类型名将移除节点前缀
@export var remove_prefix : bool = false

func _ready():
    if not Engine.is_editor_hint():
        return

    if auto_build:
        _run()

func _run():
    if not owner.scene_file_path:
        print_rich("[color=LIGHT_BLUE][%s] [color=SALMON]- 场景不存在于文件系统中" % [CLASS_PREFIX])
        return

    var _path : String = owner.scene_file_path.get_base_dir()
    var _theme : Theme

    if res_name:
        _path = _path.path_join("%s.tres" % res_name.to_lower())
    else:
        _path = _path.path_join("%s.tres" % self.name.to_lower())

    if ResourceLoader.exists(_path):
        var _resource = ResourceLoader.load(_path)
        if _resource is Theme:
            _theme = _resource
            _theme.clear()
            print_rich("[color=LIGHT_BLUE][%s] [color=LIGHT_GREEN]- 覆盖主题资源, 将移除所有类型后生成" % [CLASS_PREFIX])
        else:
            print_rich("[color=LIGHT_BLUE][%s] [color=SALMON]- 创建失败, 路径的资源类型不是 [ Theme ]" % [CLASS_PREFIX])
            print_rich("[color=LIGHT_BLUE][%s] [color=SALMON]- %s" % [CLASS_PREFIX, _path])
            return
    else:
        _theme = Theme.new()

    for node : Control in get_node_children_recursive(self, Control):
        if node.owner != self.owner:
            continue

        if node.name.begins_with(node_prefix) == false:
            continue

        var base_type = node.get_class()
        var theme_type = node.name


        if theme_type == base_type:
            if base_type != "Control":
                var debug_text = "[%s] - 不能使用内置类名作为主题变体 | %s" % [CLASS_PREFIX, node.name]
                print_rich("[color=LIGHT_CORAL]%s" % [debug_text])
            continue

        if remove_prefix:
            theme_type = theme_type.trim_prefix(node_prefix)

        node.theme_type_variation = theme_type
        _theme.add_type(theme_type)
        _theme.set_type_variation(theme_type, base_type)

        print_rich("[color=LIGHT_BLUE][%s] [color=GRAY]+ [ %s ] %s" % [CLASS_PREFIX, node.get_class(), theme_type])
        for prop in node.get_property_list():
            var prop_name : String = prop["name"]
            # 只处理主题覆盖
            if prop_name.begins_with("theme_override_") == false:
                continue
            if "/" not in prop_name:
                continue
            # 跳过未覆盖的主题
            if node.get(prop_name) == null:
                continue

            var category = prop_name.split("/")[0]
            var key = prop_name.split("/")[1]
            var value = node.get(prop_name)

            match category:
                "theme_override_colors":
                    _theme.set_color(key, theme_type, value)
                "theme_override_constants":
                    _theme.set_constant(key, theme_type, value)
                "theme_override_fonts":
                    _theme.set_font(key, theme_type, value)
                "theme_override_font_sizes":
                    _theme.set_font_size(key, theme_type, value)
                "theme_override_icons":
                    _theme.set_icon(key, theme_type, value)
                "theme_override_styles":
                    _theme.set_stylebox(key, theme_type, value)

    _theme.take_over_path(_path)
    ResourceSaver.save(_theme, _path)

    self.theme = _theme

    print_rich("[color=LIGHT_BLUE][%s] [color=LIGHT_GREEN]- Export %s" % [CLASS_PREFIX, _path])

static func get_node_children_recursive(node: Node, type: Variant = null) -> Array:
    var child_list = []
    for child in node.get_children():
        child_list.append(child)
        if child.get_child_count():
            child_list.append_array(get_node_children_recursive(child))
    if type:
        var type_list = []
        for i in child_list:
            if is_instance_of(i, type):
                type_list.append(i)
        return type_list
    return child_list
