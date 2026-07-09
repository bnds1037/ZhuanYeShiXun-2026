shader_type canvas_item;

void fragment() {
    // 计算当前像素点距离小地图中心的距离（UV 坐标中心是 0.5）
    float dist = distance(UV, vec2(0.5));
    
    // 如果距离大于 0.5（说明超出了圆形的边界），就让这个像素彻底透明
    if (dist > 0.5) {
        COLOR.a = 0.0;
    } else {
        COLOR = texture(TEXTURE, UV);
    }
}