# EM Pipelines

## TODO
* Make wiring easier
* Example apps
* Control flow for AmqpEventSource
* Transaction ID on each message
* Evented I/O for IOEventSource
* Consolidate logger and monitoring
* Default monitoring implementation
* Performance testing
* Make all events composable (e.g. new_on_event = old_on_event o new_handler)
* Detect insonsistency when handler didnt consume or pass message ahead
