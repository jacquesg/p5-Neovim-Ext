# NAME

Neovim::Ext - Perl bindings for neovim

# DESCRIPTION

Perl interface to Neovim

# FUNCTIONS

## from\_session( $session )

Create a new Nvim instance for `$session`.

## start\_host( $session )

Promote the current process into a perl plugin host for Nvim. It starts the event
loop for `$session`, listening for Nvim requests and notifications, and also
registers Nvim commands for loading/unloading perl plugins.

# METHODS

## call( $name, @args )

Call a vimscript function.

## chdir( $path )

Set the Nvim current directory.

## close( )

Close the Nvim session.

## command( $string, @args)

Execute a single ex command.

## command\_output( )

Execute a single ex command and return the output.

## err\_write( $msg )

Print `$msg` as an error message. Does not append a newline and won't be displayed
if a linefeed is not sent.

## err\_writeln( $msg )

Print `$msg` as an error message. Appends a newline so the buffer is flushed
and displayed.

## eval( $string, @args )

Evaluate a vimscript expression

## exec\_lua( $code, @args )

Execute lua code.

## feedkeys ($keys, \[$options, $escape\_csi\])

Push `$keys`< to Nvim user input buffer. Options can be a string with the following
character flags:

- "m"

    Remap keys. This is the default.

- "n"

    Do not remap keys.

- "t"
Handle keys as if typed; otherwise they are handled as if coming from a mapping. This
matters for undo, opening folds, etc.

## foreach\_rtp( \\&cb )

Invoke `\&cb` for each path in 'runtimepath'.

## input( $bytes )

Push `$bytes` to Nvim's low level input buffer. Unliked `feedkeys()` this uses the
lowest level input buffer and the call is not deferred.

## list\_runtime\_paths( )

Return a list reference of paths contained in the 'runtimepath' option.

## list\_uis( )

Gets a list of attached UIs.

## next\_message( )

Block until a message (request or notification) is available. If any messages were
previously enqueued, return the first in the queue. If not, the event loop is run
until one is received.

## out\_write( $msg, @args )

Print `$msg` as a normal message. The message is buffered and wont display
until a linefeed is sent.

## quit( \[$quit\_command\])

Send a quit command to Nvim. By default, the quit command is `qa!` which will make
Nvim quit without saving anything.

## replace\_termcodes( $string, \[$from\_part, $do\_lt, $special\] )

Replace any terminal code strings by byte sequences. The returned sequences are Nvim's
internal representation of keys. The returned sequences can be used as input to
`feekeys()`.

## request( $name, @args)

Send an API request or notification to Nvim.

## run\_loop($request\_cb, $notification\_cb, \[$setup\_cb, $err\_cb\] )

Run the event loop to receive requests and notifications from Nvim. This should not
be called from a plugin running in the host, which already runs the loop and dispatches
events to plugins.

## stop\_loop( )

Stop the event loop.

## strwidth( $string )

Return the number of display cells `$string` occupies.

## subscribe( $event )

Subscribe to an Nvim event.

## unsubscribe( $event )

Unsubscribe from an Nvim event.

# AUTHOR

Jacques Germishuys <jacquesg@striata.com>

# LICENSE AND COPYRIGHT

Copyright 2019 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
