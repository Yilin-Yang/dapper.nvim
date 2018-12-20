Debug Adapter Protocol Messages - VimL Implementation
================================================================================
https://microsoft.github.io/debug-adapter-protocol/specification

For creating/initializing DAP messages from VimL.

For the most part, these VimL types are carbon-copies of their DAP equivalents. The
most important distinction is their inclusion of a `vim_id` property and
a `vim_msg_typename` property: the former is used to identify the VimL object that made
the request/to which a response is addressed, while the latter is used to divvy
incoming messages between subscribers.
