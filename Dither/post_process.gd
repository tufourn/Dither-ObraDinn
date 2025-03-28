@tool

extends CompositorEffect
class_name DitherPostProcess

var rd : RenderingDevice
var shader : RID
var pipeline : RID

func _init():
	effect_callback_type = EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
	RenderingServer.call_on_render_thread(_init_compute)

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if shader.is_valid():
			rd.free_rid(shader)

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
				
				var uniform : RDUniform = RDUniform.new()
				uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
				uniform.binding = 0
				uniform.add_id(input_image)
				var uniform_set = UniformSetCacheRD.get_cache(shader, 0, [ uniform ])
				
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
