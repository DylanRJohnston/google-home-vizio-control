# google-home-vizio-control

A simple server for integrating Google Home voice control with the Vizio TV SmartCast API.

## Overview

```
+-------------+  "Turn on the playstation"  +--------------+
| Google Home +-----------------------------> IFTTT Applet |
+-------------+                             +------+-------+
                      Webhook Trigger              |
       +-------------------------------------------+
       |
+------v-------+     Vizio Smartcast API      +----------+
| Raspberry Pi +------------------------------> Vizio TV |
+--------------+                              +----+-----+
                         HDMI CEC                  |
       +---------------------+---------------------+
       |                     |                     |
+------v------+ +------------v-----------+ +-------v---------+
| Playstation | | Any CEC Enabled Device | | Nintendo Switch |
+-------------+ +------------------------+ +-----------------+
```

### Google Home, IFTTT, and Webhooks
IFTTT supports creating custom Google Home commands via the [Google Assistant](https://ifttt.com/google_assistant) Service. These can be linked together with the [WebHook Service](https://ifttt.com/services/maker_webhooks) to create a webhook trigger on a custom google home command such as "Hey Google, turn on the playstation".

### Webhook Triggers
This application expects a simple POST request for the device in question with the `text/plain` content type and the body as the shared secret. e.g.

```
POST /playstation HTTP/1.1
Content-Type: text/plain

SHARED_SECRET
```

### Vizio Smartcast API
Vizio TVs have a REST-ish API that is used by the SmartCast app to control the tv. The API is documented [here](https://github.com/exiva/Vizio_SmartCast_API). It can emulate all the button presses of the remote, but has a number of quirks detailed below.

* Change device input requires the key of the current input to work, therefore it is a stateful operation
* Change device input returns before the inout has actually changed so calls to current input may be incorrect
* When turning on the tv change device input may return sucesfull while not doing anything

For these reasons the change input function loops every second requested the input be changed until the current input return matches the desired input.


### CEC
CEC is a bit of a weird beast and works differently between consoles.

| Feature | Nintendo Switch | Playstation |
| --- | --- | --- |
| Can wake the TV and change the input | :heavy_check_mark: | :heavy_check_mark: |
| Wakes when the TV changes to device input | :heavy_multiplication_x: | :heavy_check_mark: |
| Turns off when the TV turns off | :heavy_check_mark: | :heavy_check_mark: |

Turning on the device when the TV changes to that input only works when the input actually *changes*. IF the TV is already on the playstation input channel then it will not wake up. For this reason, we need to switch to a different input e.g. `CAST`, and then change back in order to trigger the CEC command.

