/// @description  draw_text_plus(xl, xr, yt, text, font, *palette idx, *adjust line spacing)
/// @param xl
/// @param  xr
/// @param  yt
/// @param  text
/// @param  font
/// @param  *palette idx
/// @param  *adjust line spacing
function draw_text_plus() {

	// draw_text_() but with word wrap


	var                  _i=0;
	var _XL   = argument[_i++];
	var _XR   = argument[_i++];
	var _YT   = argument[_i++];
	var _text = argument[_i++];
	var _FONT = argument[_i++];
	var                    _PI = 0;
	if (argument_count>_i) _PI = argument[_i++];

	var _FONT_W = sprite_get_width( _FONT);
	var _FONT_H = sprite_get_height(_FONT);
	var _DIST1  = _FONT_H; // Leading (vertical dist between yt of each line)
	    _DIST1 += 2;       // Line padding
	if (argument_count>_i) _DIST1 += argument[_i++];

	var _xl,_yt, _dist1;
	var _word, _len, _pos, _pos_space, _pos_end_line;


	_xl = _XL;
	_yt = _YT;

	if (_PI) pal_swap_set(global.palette_image, _PI);
	while (true)
	{
	        _len = string_length(_text);
	    if(!_len) break;//while (true)
    
	    _pos_space    = string_pos(" ",_text);
	    _pos_end_line = string_pos(g.CHAR_END_LINE3,_text);
    
	         if (_pos_space && _pos_end_line) _pos = min(_pos_space,_pos_end_line);
	    else if (_pos_space || _pos_end_line) _pos = max(_pos_space,_pos_end_line);
	    else                                  _pos = 0;
    
    
	    if (_pos!=1)
	    {
	        if(!_pos) _word = _text;
	        else      _word = string_copy(_text, 1,_pos-1); // This truncates the 'space'/'end line' at _pos
        
	        _dist1 = string_length(_word) * _FONT_W;
	        if (_xl+_dist1>=_XR)
	        {
	            _xl  = _XL;
	            _yt += _DIST1;
	        }
        
	        draw_text_(_xl,_yt, _word, _FONT);
	        _xl += _dist1;
	    }
    
	    // Add the 'space' after the word. An 'end line' character turns into a 'space'.
	    _xl += _FONT_W;
    
	    if (_pos 
	    &&  _pos<_len )
	    {
	        // The remaining text beyond _pos
	        _text = string_copy(_text, _pos+1,_len-_pos);
        
	        if (_pos==_pos_end_line 
	        ||  _xl>=_XR)
	        {
	            _xl  = _XL;
	            _yt += _DIST1;
	        }
	    }
	    else
	    {
	        break;//while (true)
	    }
	}//while (true)
	if (_PI) pal_swap_reset();


	_yt += _FONT_H;
	//_yt += _DIST1;
	return _yt;







}
