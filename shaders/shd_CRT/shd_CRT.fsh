//
// CRT fragment shader (subtle)
//
// Samples the application surface and layers three gentle effects:
//   (a) horizontal scanlines (darken between output rows),
//   (b) a subtle aperture / RGB mask,
//   (c) a soft vignette to fake the tube's edge falloff.
// Tuned to read as "CRT-ish", not a harsh effect.
// #############################################################
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

// Output vertical resolution -> scanline frequency. Set by the rendering
// code; fall back to the native height if it was never set.
uniform float u_resY;

void main()
{
    float _resY = u_resY;
    if (_resY < 1.0)
    {
        _resY = 270.0;
    }

    vec2 _uv = v_vTexcoord;

    // Base sample of the application surface.
    vec4 _color = v_vColour * texture2D(gm_BaseTexture, _uv);

    // (a) Scanlines: one soft dark trough per output row. mix() keeps the
    //     dip shallow so it stays subtle.
    float _scan       = 0.5 + 0.5 * cos(_uv.y * _resY * 6.28318530718);
    float _scanDarken = mix(0.85, 1.0, _scan);
    _color.rgb *= _scanDarken;

    // (b) Aperture / RGB mask: bias successive screen columns slightly toward
    //     R, G or B (assumes ~16:9 output to estimate column count).
    float _col = mod(floor(_uv.x * _resY * (16.0 / 9.0)), 3.0);
    vec3  _mask;
    if (_col < 1.0)      { _mask = vec3(1.00, 0.94, 0.94); }
    else if (_col < 2.0) { _mask = vec3(0.94, 1.00, 0.94); }
    else                 { _mask = vec3(0.94, 0.94, 1.00); }
    _color.rgb *= _mask;

    // (c) Vignette: gentle darkening toward the edges/corners (fake curve).
    vec2  _vc  = _uv - 0.5;
    float _vig = 1.0 - dot(_vc, _vc) * 0.35;
    _color.rgb *= clamp(_vig, 0.0, 1.0);

    gl_FragColor = _color;
}
