//
//  ColladaNames.m
//  aotkXML
//
//  Created by victor on 3/26/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//



NSString * const kAttr_count = @"count";
NSString * const kAttr_id = @"id";
NSString * const kAttr_material = @"material";
NSString * const kAttr_name = @"name";
NSString * const kAttr_offset = @"offset";
NSString * const kAttr_opaque = @"opaque";
NSString * const kAttr_profile = @"profile";
NSString * const kAttr_semantic = @"semantic";
NSString * const kAttr_set = @"set";
NSString * const kAttr_sid = @"sid";
NSString * const kAttr_source = @"source";
NSString * const kAttr_stride = @"stride";
NSString * const kAttr_symbol = @"symbol";
NSString * const kAttr_target = @"target";
NSString * const kAttr_texcoord = @"texcoord";
NSString * const kAttr_texture = @"texture";
NSString * const kAttr_type = @"type";
NSString * const kAttr_url = @"url";
NSString * const kAttr_version = @"version";
NSString * const kAttr_xmlns = @"xmlns";


#define _kTag_ambient      "ambient"
#define _kTag_diffuse      "diffuse"
#define _kTag_emission     "emission"
#define _kTag_reflective   "reflective"
#define _kTag_reflectivity "reflectivity"
#define _kTag_shininess    "shininess"
#define _kTag_specular     "specular"
#define _kTag_transparency "transparency"
#define _kTag_transparent  "transparent"

NSString * const kTag_ambient = @ _kTag_ambient;
NSString * const kTag_diffuse = @ _kTag_diffuse;
NSString * const kTag_emission = @ _kTag_emission;
NSString * const kTag_reflective = @ _kTag_reflective;
NSString * const kTag_reflectivity = @ _kTag_reflectivity;
NSString * const kTag_shininess = @ _kTag_shininess;
NSString * const kTag_specular = @ _kTag_specular;
NSString * const kTag_transparency = @ _kTag_transparency;
NSString * const kTag_transparent = @ _kTag_transparent;

NSString * const kTag_accessor = @"accessor";
NSString * const kTag_animation = @"animation";
NSString * const kTag_asset = @"asset";
NSString * const kTag_attenuationEnd = @"attenuationEnd";
NSString * const kTag_attenuationFalloffExponent = @"attenuationFalloffExponent";
NSString * const kTag_attenuationStart = @"attenuationStart";
NSString * const kTag_authoring_tool = @"authoring_tool";
NSString * const kTag_bind_material = @"bind_material";
NSString * const kTag_bind_shape_matrix = @"bind_shape_matrix";
NSString * const kTag_blinn = @"blinn";
NSString * const kTag_camera = @"camera";
NSString * const kTag_channel = @"channel";
NSString * const kTag_COLLADA = @"COLLADA";
NSString * const kTag_color = @"color";
NSString * const kTag_contributor = @"contributor";
NSString * const kTag_controller = @"controller";
NSString * const kTag_created = @"created";
NSString * const kTag_directional = @"directional";
NSString * const kTag_double_sided = @"double_sided";
NSString * const kTag_effect = @"effect";
NSString * const kTag_extra = @"extra";
NSString * const kTag_float = @"float";
NSString * const kTag_float_array = @"float_array";
NSString * const kTag_geometry = @"geometry";
NSString * const kTag_image = @"image";
NSString * const kTag_index_of_refraction = @"index_of_refraction";
NSString * const kTag_init_from = @"init_from";
NSString * const kTag_input = @"input";
NSString * const kTag_instance_camera = @"instance_camera";
NSString * const kTag_instance_controller = @"instance_controller";
NSString * const kTag_instance_effect = @"instance_effect";
NSString * const kTag_instance_geometry = @"instance_geometry";
NSString * const kTag_instance_light = @"instance_light";
NSString * const kTag_instance_material = @"instance_material";
NSString * const kTag_instance_visual_scene = @"instance_visual_scene";
NSString * const kTag_joints = @"joints";
NSString * const kTag_lambert = @"lambert";
NSString * const kTag_library_animations = @"library_animations";
NSString * const kTag_library_cameras = @"library_cameras";
NSString * const kTag_library_controllers = @"library_controllers";
NSString * const kTag_library_effects = @"library_effects";
NSString * const kTag_library_geometries = @"library_geometries";
NSString * const kTag_library_images = @"library_images";
NSString * const kTag_library_lights = @"library_lights";
NSString * const kTag_library_materials = @"library_materials";
NSString * const kTag_library_visual_scenes = @"library_visual_scenes";
NSString * const kTag_light = @"light";
NSString * const kTag_litPerPixel = @"litPerPixel";
NSString * const kTag_material = @"material";
NSString * const kTag_matrix = @"matrix";
NSString * const kTag_mesh = @"mesh";
NSString * const kTag_modified = @"modified";
NSString * const kTag_Name_array = @"Name_array";
NSString * const kTag_newparam = @"newparam";
NSString * const kTag_node = @"node";
NSString * const kTag_optics = @"optics";
NSString * const kTag_p = @"p";
NSString * const kTag_param = @"param";
NSString * const kTag_perspective = @"perspective";
NSString * const kTag_phong = @"phong";
NSString * const kTag_polylist = @"polylist";
NSString * const kTag_profile_COMMON = @"profile_COMMON";
NSString * const kTag_rotate = @"rotate";
NSString * const kTag_sampler = @"sampler";
NSString * const kTag_sampler2D = @"sampler2D";
NSString * const kTag_scale = @"scale";
NSString * const kTag_scene = @"scene";
NSString * const kTag_skeleton = @"skeleton";
NSString * const kTag_skin = @"skin";
NSString * const kTag_source = @"source";
NSString * const kTag_surface = @"surface";
NSString * const kTag_technique = @"technique";
NSString * const kTag_technique_common = @"technique_common";
#define kTag_texture kAttr_texture
NSString * const kTag_translate = @"translate";
NSString * const kTag_triangles = @"triangles";
NSString * const kTag_up_axis = @"up_axis";
NSString * const kTag_v = @"v";
NSString * const kTag_vcount = @"vcount";
NSString * const kTag_vertex_weights = @"vertex_weights";
NSString * const kTag_vertices = @"vertices";
NSString * const kTag_visual_scene = @"visual_scene";
NSString * const kTag_xfov = @"xfov";
NSString * const kTag_zfar = @"zfar";
NSString * const kTag_znear = @"znear";

NSString * const kValue_name_INTERPOLATION = @"INTERPOLATION";
NSString * const kValue_name_JOINT = @"JOINT";
NSString * const kValue_name_S = @"S";
NSString * const kValue_name_T = @"T";
NSString * const kValue_name_TIME = @"TIME";
NSString * const kValue_name_TRANSFORM = @"TRANSFORM";
NSString * const kValue_name_WEIGHT = @"WEIGHT";
NSString * const kValue_name_X = @"X";
NSString * const kValue_name_Y = @"Y";
NSString * const kValue_name_Z = @"Z";
NSString * const kValue_semantic_INPUT = @"INPUT";
NSString * const kValue_semantic_INV_BIND_MATRIX = @"INV_BIND_MATRIX";
NSString * const kValue_semantic_JOINT = @"JOINT";
NSString * const kValue_semantic_NORMAL = @"NORMAL";
NSString * const kValue_semantic_OUTPUT = @"OUTPUT";
NSString * const kValue_semantic_POSITION = @"POSITION";
NSString * const kValue_semantic_TEXCOORD = @"TEXCOORD";
NSString * const kValue_semantic_COLOR = @"COLOR";
NSString * const kValue_semantic_VERTEX = @"VERTEX";
NSString * const kValue_semantic_WEIGHT = @"WEIGHT";
NSString * const kValue_sid_rotationX = @"rotationX";
NSString * const kValue_sid_rotationY = @"rotationY";
NSString * const kValue_sid_rotationZ = @"rotationZ";
NSString * const kValue_type_2d = @"2D";
NSString * const kValue_type_float = @"float";
NSString * const kValue_type_float4x4 = @"float4x4";
NSString * const kValue_type_name = @"name";
