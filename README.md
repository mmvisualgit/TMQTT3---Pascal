# TMQTT 3 for Lazarus/FPC by MmVisual (Markus M.)


## Introduction

TMQTT is a non-visual Pascal Client Library for the IBM Websphere MQ Transport Telemetry protocol ( http://mqtt.org ).
TMQTT is a partly re-write of the original TMQTT2 https://github.com/jamiei/Delphi-TMQTT2, with a lot of fixed bugs and additional features.
MQTT is an IoT protocol, further information can be found here: http://mqtt.org/
The Protocoll specification is in this document: http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.pdf

This component need's a Broker as server. You can find a lot of YouToube Videos how to install a MQTT Broker like this: https://www.youtube.com/watch?v=kQ159NLCJts


## Points of Note

* All features from the protocol MQTT V3.1.1 are implemented
* It is currently FPC compatible and tested with Windows and Linux
* Supports QoS 0, 1 and 2.
* AutoResponse Feature for QoS 1 and 2
* Connection or transmission Timeout
* Fast nonblocking Task with a minimum of CPU load


## Usage

There is a sample Lazarus project to see how the MQTT library can be used.

Special thanks for Jamie who write the initial version.
If you are using my TMQTT then I would to love hear about how you’re using it, if you do appreciate it, please let me know!
