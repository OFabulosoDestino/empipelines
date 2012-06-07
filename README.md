# EmPipelines
[![Build Status](https://secure.travis-ci.org/soundcloud/empipelines.png?branch=message_validity)](http://travis-ci.org/soundcloud/empipelines?branch=message_validity)

## Message States

* **Consumed:** The message went through all relevant stages and was
fully consumed.
* **Broken:** The message *left the EventSource* in an invalid
state and should not be processed. If the message was corrupted by a
previous stage it should not be broken, just rejected.
* **Rejected:** The message is correct but this pipeline instance
cannot process it, probably due to some temporary problem.

### TODO
* Make wiring easier
* Example apps
* Evented I/O for IOEventSource
* Performance testing
* Detect insonsistency when handler didn't consume or pass message ahead
* Is callback in the stage's signature redundant? Could we just return
the message?
