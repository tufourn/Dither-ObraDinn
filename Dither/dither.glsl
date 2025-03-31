#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 0) uniform image2D color_image;

layout(set = 0, binding = 1) uniform samplerCube cubemap_image;

layout(push_constant, std430) uniform PushConstants {
	vec4 frustum_top_left;
	vec4 frustum_top_right;
	vec4 frustum_bottom_left;
	vec4 frustum_bottom_right;
	vec2 raster_size;
	vec2 reserved;
} pc;

vec3 get_direction_to_pixel(vec2 uv) {
	float u = float(uv.x) / pc.raster_size.x;
	float v = float(uv.y) / pc.raster_size.y;

	vec3 top = mix(pc.frustum_top_left.xyz, pc.frustum_top_right.xyz, u);
	vec3 bot = mix(pc.frustum_bottom_left.xyz, pc.frustum_bottom_right.xyz, u);
	vec3 direction = mix(top, bot, v);

	return normalize(direction);
}

void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	ivec2 size = ivec2(pc.raster_size);

	if (uv.x >= size.x || uv.y >= size.y) {
		return;
	}

	vec4 color = imageLoad(color_image, uv);

	float lum = color.r * 0.2125 + color.g * 0.7154 + color.b * 0.0721;
	float bayer_threshold = texture(cubemap_image, get_direction_to_pixel(uv)).r;
	color.rgb = vec3(step(bayer_threshold, lum));
	// color.rgb = vec3(bayer_threshold, bayer_threshold, bayer_threshold); // for testing

	imageStore(color_image, uv, color);
}
