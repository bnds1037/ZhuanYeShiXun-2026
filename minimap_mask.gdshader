shader_type canvas_item;

void fragment() {
    // 显式声明浮点数，计算当前像素到中心点 (0.5, 0.5) 的距离
    float dist = distance(UV, vec2(0.5, 0.5));
    
    // 如果距离大于圆半径 0.5，则通过 alpha 通道完全裁剪
    if (dist > 0.5) {
        COLOR.a = 0.0;
    } else {
        COLOR = texture(TEXTURE, UV);
    }
}