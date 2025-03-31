@tool

extends EditorScript

const tiling : int = 64 # power of 2
const resolution : int = 2048
 
const bayer_size = 8
const bayer = [
	[ 0.0/64.0,  32.0/64.0,  8.0/64.0, 40.0/64.0,  2.0/64.0, 34.0/64.0, 10.0/64.0, 42.0/64.0 ],
	[ 48.0/64.0, 16.0/64.0, 56.0/64.0, 24.0/64.0, 50.0/64.0, 18.0/64.0, 58.0/64.0, 26.0/64.0 ],
	[ 12.0/64.0, 44.0/64.0,  4.0/64.0, 36.0/64.0, 14.0/64.0, 46.0/64.0,  6.0/64.0, 38.0/64.0 ],
	[ 60.0/64.0, 28.0/64.0, 52.0/64.0, 20.0/64.0, 62.0/64.0, 30.0/64.0, 54.0/64.0, 22.0/64.0 ],
	[  3.0/64.0, 35.0/64.0, 11.0/64.0, 43.0/64.0,  1.0/64.0, 33.0/64.0,  9.0/64.0, 41.0/64.0 ],
	[ 51.0/64.0, 19.0/64.0, 59.0/64.0, 27.0/64.0, 53.0/64.0, 21.0/64.0, 61.0/64.0, 29.0/64.0 ],
	[ 15.0/64.0, 47.0/64.0,  7.0/64.0, 39.0/64.0, 13.0/64.0, 45.0/64.0,  5.0/64.0, 37.0/64.0 ],
	[ 63.0/64.0, 31.0/64.0, 55.0/64.0, 23.0/64.0, 61.0/64.0, 29.0/64.0, 57.0/64.0, 25.0/64.0 ]
];

func _run() -> void:
	var image_sphere : Image = Image.create_empty(resolution, resolution, false, Image.FORMAT_L8)
	var image_square : Image = Image.create_empty(resolution, resolution, false, Image.FORMAT_L8)
	for x in range(resolution):
		for y in range(resolution):
			var cube_x : float = (float(x) / (resolution - 1) - 0.5) * 2.0
			var cube_y : float = (float(y) / (resolution - 1) - 0.5) * 2.0
			const cube_z : float = 1.0 # all 6 faces of cubemap use the same texture so we only do one face (z+)
			
			var dir = Vector3(cube_x, cube_y, cube_z)
			dir /= dir.length()
			
			var angle_x : float = atan2(dir.z, dir.x) # pi/4 to 3pi/4
			var angle_y : float = atan2(dir.z, dir.y) # pi/4 to 3pi/4
			
			var bayer_x : int = floori((angle_x - PI / 4) / (PI / 2) * (bayer_size * tiling)) % bayer_size
			var bayer_y : int = floori((angle_y - PI / 4) / (PI / 2) * (bayer_size * tiling)) % bayer_size
			
			if (x == 0):
				bayer_x = bayer_size - 1
			if (y == 0):
				bayer_y = bayer_size - 1
			var bayer_val = bayer[bayer_x][bayer_y]
			image_sphere.set_pixel(x, y, Color(bayer_val, bayer_val, bayer_val, 1.0))
			
			# normal tiled bayer texture for testing
			var pixel_per_matrix : int = resolution / floor(tiling)
			var pixel_per_matrix_point : int = pixel_per_matrix / floor(bayer_size)
			
			var bayer_x_square = floor(float(x % pixel_per_matrix) / pixel_per_matrix_point)
			var bayer_y_square = floor(float(y % pixel_per_matrix) / pixel_per_matrix_point)
			var bayer_val_square = bayer[bayer_x_square][bayer_y_square]
			image_square.set_pixel(resolution - 1 - x, resolution - 1 - y, Color(bayer_val_square, bayer_val_square, bayer_val_square, 1.0))
			
	var image_sphere_path = "res://Dither/cubemap_face.png"
	var image_square_path = "res://Dither/bayer_texture.png"
	image_sphere.save_png(image_sphere_path)
	image_square.save_png(image_square_path)
