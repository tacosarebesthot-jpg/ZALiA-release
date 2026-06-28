//
// Sharp bilinear upscale fragment shader
//
// Crisp like nearest-neighbour but without uneven pixels: works in texel
// space, then applies a narrow smoothstep to the fractional part so each
// texel reads as a flat (snapped) block, with only a thin blend band right
// at the texel boundary to kill shimmer.
// #############################################################
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

// Source texture size in texels. The rendering code sets this each frame;
// fall back to the native render size if it was never set.
uniform vec2 u_texSize;

void main()
{
    vec2 _texSize = u_texSize;
    if (_texSize.x < 1.0 || _texSize.y < 1.0)
    {
        _texSize = vec2(480.0, 270.0);
    }

    // Move into texel space.
    vec2 _texel  = v_vTexcoord * _texSize;

    // Nearest texel centre, and the signed offset from it (-0.5 .. 0.5).
    vec2 _centre = floor(_texel) + 0.5;
    vec2 _frac   = _texel - _centre;

    // Narrow smoothstep on the fractional part: flat (snapped to the centre)
    // across most of the texel, ramping to the neighbour only inside a thin
    // band near the boundary. Smaller _band = sharper edges.
    const float _band = 0.25;
    vec2 _offset = sign(_frac) * smoothstep(0.5 - _band, 0.5 + _band, abs(_frac)) * 0.5;

    // Snap back and divide out of texel space.
    vec2 _uv = (_centre + _offset) / _texSize;

    gl_FragColor = v_vColour * texture2D(gm_BaseTexture, _uv);
}
