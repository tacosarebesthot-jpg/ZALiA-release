// Based off: https://github.com/h3rb/gml-pro/blob/bf2d2a38c5aa3d1ff73bcb605dbae8e16aa7022b/GML-Pro-Pack2.gmx/shaders/gles_Bloom.shader
varying vec2 v_vTexcoord;

uniform sampler2D u_texture;
uniform float u_dist_x; // texel width
uniform float u_dist_y; // texel height
uniform float u_a;
uniform float u_b;
uniform float u_c;
uniform float u_d;
uniform float u_e;
uniform float u_f;
uniform float u_g;
//uniform bool u_scanlines_effect_enabled;


void main()
{
    //if(!u_scanlines_effect_enabled 
    //||  true )
    vec4 _sum = vec4(0.0);
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x*-4.0,u_dist_y*-3.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x*-3.0,u_dist_y*-3.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x*-2.0,u_dist_y*-3.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x*-1.0,u_dist_y*-3.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x* 0.0,u_dist_y*-3.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x* 1.0,u_dist_y*-3.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x* 2.0,u_dist_y*-3.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x* 3.0,u_dist_y*-3.0)*u_a)) * u_g;
    //                                                                              //
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x*-4.0,u_dist_y*-2.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x*-3.0,u_dist_y*-2.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x*-2.0,u_dist_y*-2.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x*-1.0,u_dist_y*-2.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x* 0.0,u_dist_y*-2.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x* 1.0,u_dist_y*-2.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x* 2.0,u_dist_y*-2.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x* 3.0,u_dist_y*-2.0)*u_a)) * u_g;
    //                                                                              //
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x*-4.0,u_dist_y*-1.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x*-3.0,u_dist_y*-1.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x*-2.0,u_dist_y*-1.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x*-1.0,u_dist_y*-1.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x* 0.0,u_dist_y*-1.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x* 1.0,u_dist_y*-1.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x* 2.0,u_dist_y*-1.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x* 3.0,u_dist_y*-1.0)*u_a)) * u_g;
    //                                                                              //
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x*-4.0,u_dist_y* 0.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x*-3.0,u_dist_y* 0.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x*-2.0,u_dist_y* 0.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x*-1.0,u_dist_y* 0.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x* 0.0,u_dist_y* 0.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x* 1.0,u_dist_y* 0.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x* 2.0,u_dist_y* 0.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x* 3.0,u_dist_y* 0.0)*u_a)) * u_g;
    //                                                                              //
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x*-4.0,u_dist_y* 1.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x*-3.0,u_dist_y* 1.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x*-2.0,u_dist_y* 1.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x*-1.0,u_dist_y* 1.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x* 0.0,u_dist_y* 1.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x* 1.0,u_dist_y* 1.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x* 2.0,u_dist_y* 1.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x* 3.0,u_dist_y* 1.0)*u_a)) * u_g;
    //                                                                              //
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x*-4.0,u_dist_y* 2.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x*-3.0,u_dist_y* 2.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x*-2.0,u_dist_y* 2.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x*-1.0,u_dist_y* 2.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x* 0.0,u_dist_y* 2.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x* 1.0,u_dist_y* 2.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x* 2.0,u_dist_y* 2.0)*u_a)) * u_g;
    _sum += texture2D(u_texture, v_vTexcoord+(vec2(u_dist_x* 3.0,u_dist_y* 2.0)*u_a)) * u_g;
    
    
    vec4     _COLOR = texture2D(u_texture,v_vTexcoord);
         if (_COLOR.r<u_e) gl_FragColor = _sum*_sum*u_b + _COLOR;
    else if (_COLOR.r<u_f) gl_FragColor = _sum*_sum*u_c + _COLOR;
    else                   gl_FragColor = _sum*_sum*u_d + _COLOR;
}




