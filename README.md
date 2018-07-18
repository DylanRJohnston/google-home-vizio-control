# google-home-vizio-control

A simple server for integrating Google Home voice control with the Vizio TV SmartCast API. [Demo Here](https://www.youtube.com/watch?v=Gl37UplXswY)

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

* Change device input requires the key of the current input to work, therefore it is a statefull operation
* Change device input returns before the input has actually changed so calls to current input may be incorrect
* When turning on the tv change device input may return successful while not doing anything

For these reasons the change input function loops every second requested the input be changed until the current input return matches the desired input.


### CEC
CEC is a bit of a weird beast and works differently between consoles.

| Feature | Nintendo Switch | Playstation |
| --- | --- | --- |
| Can wake the TV and change the input | :heavy_check_mark: | :heavy_check_mark: |
| Wakes when the TV changes to device input | :heavy_multiplication_x: | :heavy_check_mark: |
| Turns off when the TV turns off | :heavy_check_mark: | :heavy_check_mark: |

Turning on the device when the TV changes to that input only works when the input actually *changes*. IF the TV is already on the playstation input channel then it will not wake up. For this reason, we need to switch to a different input e.g. `CAST`, and then change back in order to trigger the CEC command.

## Security Considerations
For IFTTT to be able to call the webhook the server must be exposed to the internet. A few things to think about.

* To protect the application shared secret please put the server behind a SSL proxy such as [nginx](https://blog.thibmaekelbergh.be/post/super-simple-ssl-proxy-for-raspberry-pi/). You can get a free SSL cert from [Let's Encrypt](https://letsencrypt.org/).
* I've used a constant time comparator for checking the secret, but there could be more advanced timing attack opportunities.
* Please run the server in a restricted user group without write access or read access outside of the application directory
* To protect against DDoS consider placing the API behind [Cloudflare](https://www.cloudflare.com/) or some similar service.

But on the other hand, this is all probably over kill since who's going to attack your TV? ¯\_(ツ)_/¯