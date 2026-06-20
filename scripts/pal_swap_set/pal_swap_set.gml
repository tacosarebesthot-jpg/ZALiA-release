/// @description  pal_swap_set(palette_sprite_index, palette_index);
/// @param palette_sprite_index
/// @param  palette_index
function pal_swap_set() {

	// Based off Pixelated Pope's script


	if(!global.use_pal_swap 
	|| !argument[1] 
	||  argument[1]>=global.palette_image_w )
	{
	    exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	}

	if (global.palette_image_IS_SURFACE)
	{    if(!surface_exists(argument[0])) exit;  } // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	else if( !sprite_exists(argument[0])) exit;    // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!




	// ------------------------------------------------------------
	shader_set(global.Pal_Shader);
	var _Palette_IMAGE = argument[0]; // `global.palette_image`
	var _Palette_INDEX = argument[1];


	var _TEX;
	if (global.palette_image_IS_SURFACE) _TEX = surface_get_texture(_Palette_IMAGE);
	else                                 _TEX =  sprite_get_texture(_Palette_IMAGE, 0);
	texture_set_stage(global.Pal_Texture, _TEX);
	//texture_set_interpolation_ext(global.Pal_Texture, 1); // Commenting this out. Everything seems to work fine without it.


	var _Texel_W  = texture_get_texel_width( _TEX);
	var _Texel_H  = texture_get_texel_height(_TEX);
	var _Texel_W_ = _Texel_W * 0.5;
	var _Texel_H_ = _Texel_H * 0.5;


	/* `_VAL0/1/2/3`: coords of `_Palette_IMAGE`(`global.palette_image`)
	within its texture page (or within itself if it's a surface)
	*/
	var _VAL0, _VAL1, _VAL2, _VAL3;
	if (global.palette_image_IS_SURFACE)
	{
	    _VAL0 =           _Texel_W_;
	    _VAL1 =           _Texel_H_;
	    _VAL2 = 1.0     + _Texel_W_;
	    _VAL3 = 1.0     + _Texel_H_;
	}
	else
	{   /* `_UVs`: coords of `_Palette_IMAGE`(`global.palette_image`)
	    within its texture page
	    */
	    var _UVs = sprite_get_uvs(_Palette_IMAGE, 0);
	    _VAL0 = _UVs[0] + _Texel_W_; // 0: xl
	    _VAL1 = _UVs[1] + _Texel_H_; // 1: yt
	    _VAL2 = _UVs[2] + _Texel_W_; // 2: xr
	    _VAL3 = _UVs[3] + _Texel_H_; // 3: yb
	    _UVs = 0;
	}


	shader_set_uniform_f(global.Pal_Texel_Size, _Texel_W, _Texel_H);
	shader_set_uniform_f(global.Pal_UVs, _VAL0, _VAL1, _VAL2, _VAL3);
	shader_set_uniform_f(global.Pal_Index, _Palette_INDEX);




	/* // ------------ ORIGINAL --------------
	///pal_swap_set(palette_sprite_index, palette_index,palette is surface);
	shader_set(Pal_Shader);
	var _pal_sprite=argument[0];
	var _pal_index=argument[1];

	if(!argument[2])
	{   //Using a sprite based palette

	    var tex = sprite_get_texture(_pal_sprite, 0);
	    var UVs = sprite_get_uvs(_pal_sprite, 0);
    
	    texture_set_stage(Pal_Texture, tex);
	    texture_set_interpolation_ext(Pal_Texture, 1)
    
	    var texel_x = texture_get_texel_width(tex);
	    var texel_y = texture_get_texel_height(tex);
	    var texel_hx = texel_x * 0.5;
	    var texel_hy = texel_y * 0.5;
    
	    shader_set_uniform_f(Pal_Texel_Size, texel_x, texel_y);
	    shader_set_uniform_f(Pal_UVs, UVs[0] + texel_hx, UVs[1] + texel_hy, UVs[2] + texel_hx, UVs[3] + texel_hy);
	    shader_set_uniform_f(Pal_Index, _pal_index);
	}
	else
	{   //Using a surface based palette
	    var tex = surface_get_texture(_pal_sprite);
    
	    texture_set_stage(Pal_Texture, tex);
	    texture_set_interpolation_ext(Pal_Texture, 1)
    
	    var texel_x = texture_get_texel_width(tex);
	    var texel_y = texture_get_texel_height(tex);
	    var texel_hx = texel_x * 0.5;
	    var texel_hy = texel_y * 0.5;
    
	    shader_set_uniform_f(Pal_Texel_Size, texel_x, texel_y);
	    shader_set_uniform_f(Pal_UVs, texel_hx, texel_hy, 1.0+texel_hx, 1.0+texel_hy);
	    shader_set_uniform_f(Pal_Index, _pal_index);
	}
	*/





}
