@tool

extends EditorScript

const slice_count : int = 64
const resolution : int = 2048
 
# 4x4 bayer matrix
const bayer = [
	[00.0/16.0, 12.0/16.0, 03.0/16.0, 15.0/16.0],
	[08.0/16.0, 04.0/16.0, 11.0/16.0, 07.0/16.0],
	[02.0/16.0, 14.0/16.0, 01.0/16.0, 13.0/16.0],
	[10.0/16.0, 06.0/16.0, 09.0/16.0, 05.0/16.0]
]

func _run() -> void:
	var image : Image = Image.create_empty(resolution, resolution, false, Image.FORMAT_L8)
	var half_res : int = resolution / floor(2)
	for x in range(resolution):
		for y in range(resolution):
			# map cube coords to sphere in cartesian
			var cube_x = float(x - half_res) / half_res
			var cube_y = float(y - half_res) / half_res
			const cube_z = 1.0 # all 6 faces of cubemap use the same texture so we only do one face (z+)
			
			# https://mathproofs.blogspot.com/2005/07/mapping-cube-to-sphere.html
			# x and y goes from -sqrt(2) / 2 to sqrt(2) / 2
			var sphere_x = cube_x * sqrt(1 - cube_y ** 2 / 2 - cube_z ** 2 / 2 + cube_y ** 2 * cube_z ** 2 / 3)
			var sphere_y = cube_y * sqrt(1 - cube_z ** 2 / 2 - cube_x ** 2 / 2 + cube_z ** 2 * cube_x ** 2 / 3)
			# var sphere_z = cube_z * sqrt(1 - cube_x ** 2 / 2 - cube_y ** 2 / 2 + cube_x ** 2 * cube_y ** 2 / 3)
			
			# normalize to 0-1
			var uv_x = (sphere_x + sqrt(2) / 2) / sqrt(2)
			var uv_y = (sphere_y + sqrt(2) / 2) / sqrt(2)
			
			uv_x = fmod(uv_x * slice_count, 1.0)
			uv_y = fmod(uv_y * slice_count, 1.0)
			
			var bayer_x = floor(uv_x * 4)
			var bayer_y = floor(uv_y * 4)
			var bayer_val = bayer[bayer_x][bayer_y]
			image.set_pixel(x, y, Color(bayer_val, bayer_val, bayer_val, 1.0))
			
	var image_path = "res://Dither/cubemap_face.png"
	image.save_png(image_path)
	
