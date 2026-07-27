/// @description  zweb_open_page(path)
/// @param path   route on the built-in server, e.g. "/jukebox" or "/twitch"
function zweb_open_page(_path) {

	// Opens one of the game's own companion pages in the PLAYER'S DEFAULT BROWSER.
	//
	// GML has no shell-exec, so we cannot launch the isolated Chrome profile the dev
	// .cmd files use -- and we should not want to. url_open hands the URL to whatever
	// browser the player already uses, which is the whole point: "just open a webpage".
	//
	// The pages are served by obj_zalia_web on loopback only, so this URL is
	// meaningless to anyone but this machine. Nothing here is a security boundary --
	// obj_zalia_web itself refuses non-local clients.

	if (!variable_global_exists("zweb_up") || !global.zweb_up)
	{
		// Server never bound (port busy, most likely another copy of the game is
		// already running). Opening the URL anyway would dump the player on a
		// connection-refused page with no explanation, which reads as "the game is
		// broken" rather than "something else has the port".
		return false;
	}

	var _port = variable_global_exists("zweb_port") ? global.zweb_port : 8777;

	// 127.0.0.1 rather than "localhost": some systems resolve localhost to ::1 first,
	// and the server binds IPv4. The loopback guard in obj_zalia_web accepts both, but
	// only if the connection actually lands.
	url_open("http://127.0.0.1:" + string(_port) + _path);

	return true;
}
