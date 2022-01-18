# ObsWs
OBS Websocket API For GDScript.  This library implements the WebSocket API for OBS WebSocket, allowing for Godot to interface with OBS.  Structure of the library keeps things simple, as to allow for easy implementation based upon utilizing the API given by the OBS WebSocket API.  It has a similar ideal behind it as the Python simpleobsws, keeping things as lean as possible with the implementation.

## General API
### ObsWs
Primary class to interface with OBS WebSocket.

### Properties:
- host (String)
> Hostname or IP to connect to for OBS WebSocket
- port (String)
> Port in which to connect to for OBS WebSocket
- password (String)
> Password to provide when authenticating to the OBS WebSocket Server.

### Events:
- obs_connected()
> Fired when ObsWs has successfully connected.  Library will check to see if OBS is requiring Authentication, and automatically provide authentication.
- obs_disconnected()
> Fired when ObsWs has been disconnected.
- obs_event(event:String, data:Dictionary)
> Executed when an Event is sent from OBS WebSocket server, allowing for response to certain events.
- obs_response(command:String, data:Dictionary)
> Executed when an Response to a Command is sent from the OBS WebSocket server.
- obs_error(data:Dictionary)
> An error ocurred on the OBS WebSocket server, or an internal error ocurred.

### Methods:
- connect_to_host() -> bool
> Establishes a connection to the OBS WebSocket server, using the provided host, port and password provided.
- command(cmd:String, args:Dictionary) -> void
> Sends a Command to OBS WebSocket server.  All commands are ASynchronous, and require connecting to the obs_response() event, in order to see the result of the command.

## Caveats
ObsWs converts JSON Responses from OBS WebSocket Server into Dictionaries for easier access.  You can utilize the two methods for retrieving values from a Dictionary, be it the [] operator, such as data["name"] or the dot notation method, such as data.name.  Due to this, ObsWs processes the JSON Reply, and converts any keys that have a - in them, to _. So for example: Command: GetSceneList returns a Dictionary of "current-scene" and "scenes".  ObsWs will translate current-scene to current_scene to allow for the dot notation method of accessing data on a Dictionary.  So when recieving data, use the _ method for accessing the specified variable.  When sending commands, use the - for separating the names.  See the demo project for example of how to use library.
