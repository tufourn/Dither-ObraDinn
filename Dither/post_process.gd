@tool

extends CompositorEffect
class_name DitherPostProcess

var rd : RenderingDevice

var shader : RID
var pipeline : RID

var nearest_sampler : RID
var cubemap_texture : RID

func _init():
	effect_callback_type = EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
	RenderingServer.call_on_render_thread(_init_compute)

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if shader.is_valid():
			rd.free_rid(shader)
		if nearest_sampler.is_valid():
			rd.free_rid(nearest_sampler)
		if cubemap_texture.is_valid():
			rd.free_rid(cubemap_texture)

func _render_callback(p_effect_callback_type, p_render_data):
	if rd and p_effect_callback_type == EFFECT_CALLBACK_TYPE_POST_TRANSPARENT and pipeline.is_valid():
		var render_scene_buffers : RenderSceneBuffersRD = p_render_data.get_render_scene_buffers()
		var render_scene_data : RenderSceneDataRD = p_render_data.get_render_scene_data()
		if render_scene_buffers and render_scene_data:
			var render_size = render_scene_buffers.get_internal_size()
			if render_size.x == 0 and render_size.y == 0:
				return
				
			var x_groups = (render_size.x - 1) / 8 + 1
			var y_groups = (render_size.y - 1) / 8 + 1
			var z_groups = 1
			
			var push_constants : PackedFloat32Array = PackedFloat32Array()
			push_constants.push_back(render_size.x)
			push_constants.push_back(render_size.y)
			push_constants.push_back(0.0) # pad
			push_constants.push_back(0.0) # pad
			
			var view_count = render_scene_buffers.get_view_count()
			for view in range(view_count):
				var input_image = render_scene_buffers.get_color_layer(view)
				
				var color_image : RDUniform = RDUniform.new()
				color_image.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
				color_image.binding = 0
				color_image.add_id(input_image)
				
				var cubemap_image : RDUniform = RDUniform.new()
				cubemap_image.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
				cubemap_image.binding = 1
				cubemap_image.add_id(nearest_sampler)
				cubemap_image.add_id(cubemap_texture)
				
				var uniform_set = UniformSetCacheRD.get_cache(shader, 0, [ color_image, cubemap_image ])
				
				var compute_list = rd.compute_list_begin()
				rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
				rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
				rd.compute_list_set_push_constant(compute_list, push_constants.to_byte_array(), push_constants.size() * 4)
				rd.compute_list_dispatch(compute_list, x_groups, y_groups, z_groups)
				rd.compute_list_end()

func _init_compute():
	rd = RenderingServer.get_rendering_device()
	if !rd:
		return
		
	var shader_file = load("res://Dither/dither.glsl")
	var shader_spirv : RDShaderSPIRV = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	
	if shader_spirv.compile_error_compute != "":
		push_error(shader_spirv.compile_error_compute)
	
	pipeline = rd.compute_pipeline_create(shader)
	
	var sampler_state = RDSamplerState.new()
	sampler_state.min_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	sampler_state.mag_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	nearest_sampler = rd.sampler_create(sampler_state)
	
	var bayer : CompressedTexture2D = load("res://Dither/bayer.png")
	var bayer_img : Image = bayer.get_image()
	bayer_img.convert(Image.FORMAT_R8)
	
	var bayer_img_data : PackedByteArray = bayer_img.get_data()
	var cubemap_data : Array[PackedByteArray] = []
	for i in range(6):
		cubemap_data.push_back(bayer_img_data)
	
	var cubemap_format : RDTextureFormat = RDTextureFormat.new()
	cubemap_format.format = RenderingDevice.DATA_FORMAT_R8_UNORM
	cubemap_format.texture_type = RenderingDevice.TEXTURE_TYPE_CUBE
	cubemap_format.usage_bits = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
	cubemap_format.array_layers = 6
	cubemap_format.width = bayer.get_width()
	cubemap_format.height = bayer.get_height()

	var cubemap_view : RDTextureView = RDTextureView.new()
	
	cubemap_texture = rd.texture_create(cubemap_format, cubemap_view, cubemap_data)
