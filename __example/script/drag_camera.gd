extends Camera2D

# 配置参数
@export var zoom_speed: float = 0.1     # 滚轮缩放速度
@export var min_zoom: float = 0.3      # 最小缩放值
@export var max_zoom: float = 10.0     # 最大缩放值
@export var smooth_speed: float = 10.0 # 平滑移动速度

var _is_dragging := false
var _last_drag_screen_pos: Vector2

func _input(event: InputEvent):
    # 鼠标中键拖动平移
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_MIDDLE:
            if event.pressed:
                _is_dragging = true
                _last_drag_screen_pos = event.position
            else:
                _is_dragging = false

    # 滚轮缩放（以鼠标位置为中心）
    if event is InputEventMouseButton and event.pressed:
        var zoom_direction := 0
        match event.button_index:
            MOUSE_BUTTON_WHEEL_UP:    # 放大
                zoom_direction = 1
            MOUSE_BUTTON_WHEEL_DOWN:  # 缩小
                zoom_direction = -1

        if zoom_direction != 0:
            var mouse_world_pos_before = get_global_mouse_position()

            # 计算新缩放值
            var new_zoom = (zoom + Vector2.ONE * zoom_speed * zoom_direction).clamp(
                Vector2.ONE * min_zoom,
                Vector2.ONE * max_zoom
            )

            # 应用缩放
            zoom = new_zoom

            # 调整位置保持鼠标指向的世界坐标不变
            var mouse_world_pos_after = get_global_mouse_position()
            position += (mouse_world_pos_before - mouse_world_pos_after)

    # 鼠标拖动时的移动
    if _is_dragging and event is InputEventMouseMotion:
        var drag_offset = (_last_drag_screen_pos - event.position) / zoom.x
        position += drag_offset
        _last_drag_screen_pos = event.position
