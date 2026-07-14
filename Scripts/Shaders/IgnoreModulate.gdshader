shader_type canvas_item;

// Add a custom uniform to set your child's color manually
uniform vec4 custom_modulate : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void vertex() {
    // Reset the vertex color to pure white, killing the parent's modulation
    COLOR = vec4(1.0, 1.0, 1.0, 1.0);
}

void fragment() {
    // Multiply the texture by your custom color instead of the inherited COLOR
    COLOR = texture(TEXTURE, UV) * custom_modulate;
}