// Simple passthrough fragment shader
//
// #############################################################
// Based off: GameMaker Casts - https://www.youtube.com/watch?v=jjUkQJJokCU
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform float u_texture_w;
uniform float u_texture_h;

uniform float u_line_brightness;
uniform float u_line_height;


void main()
{
    vec4 _color = v_vColour * texture2D(gm_BaseTexture,v_vTexcoord);
    
    if (mod(floor(u_texture_h*v_vTexcoord.y), u_line_height*2.0) < u_line_height)
    {
        _color.rgb *= vec3(u_line_brightness);
    }
    
    gl_FragColor = _color;
}




