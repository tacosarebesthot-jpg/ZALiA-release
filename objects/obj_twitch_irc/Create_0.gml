// In-game Twitch IRC (no-bot mode). Off by default.
//
// This object is purely the HOST for the Async-Networking RECEIVE event below
// (Other_68). It is created on demand by twitch_irc_connect() -- NOT placed in a
// room and NOT auto-connecting here, so creating the instance can never recurse
// back into connect(). All connect/disconnect logic is driven from the DEV TOOLS
// "TWITCH IRC" toggle -> twitch_irc_connect() / twitch_irc_disconnect().
//
// Persistent so the socket + receive event survive room changes.
