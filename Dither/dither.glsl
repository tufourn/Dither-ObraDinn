#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 0) uniform image2D color_image;

layout(push_constant, std430) uniform Params {
	vec2 raster_size;
	vec2 reserved;
} pc;

const mat4 bayer_index = mat4(
	vec4(00.0/16.0, 12.0/16.0, 03.0/16.0, 15.0/16.0),
	vec4(08.0/16.0, 04.0/16.0, 11.0/16.0, 07.0/16.0),
	vec4(02.0/16.0, 14.0/16.0, 01.0/16.0, 13.0/16.0),
	vec4(10.0/16.0, 06.0/16.0, 09.0/16.0, 05.0/16.0));

void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	ivec2 size = ivec2(pc.raster_size);

	if (uv.x >= size.x || uv.y >= size.y) {
		return;
	}

	vec4 color = imageLoad(color_image, uv);

	float lum = color.r * 0.2125 + color.g * 0.7154 + color.b * 0.0721;

	ivec2 bayer_uv = uv;
	float bayer_value = bayer_index[bayer_uv.x % 4][bayer_uv.y % 4];
	
	color.rgb = vec3(step(bayer_value, lum));

	imageStore(color_image, uv, color);
}
