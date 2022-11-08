# wifi-hotspot

Create an autonomous home automation network.

Connect directly your wifi sensors / cams / lights / outlets to hassio.

With this solution, your device will be in an dedicated wireless
network.

Perfect for a first low cost installation in a small house, apartment or shed.

### Sample of network Architecture

![Archi](https://raw.githubusercontent.com/ldrago63/my-hassio-addons/main/hassio-wifi-hotspot/readme-resources/architecture.png)

## Installation

For installation read
[the official instructions](https://www.home-assistant.io/hassio/installing_third_party_addons/)
on the Home Assistant website and use github url :


### Sample of valid configuration

The available configuration options are as follows (this is filled
in with some example data):

```
interface: wlan0
ssid: 'MY_HASSI_WIFI'
wpa_passphrase: 'SECURED_WPA_PASS'
channel: 6
address: 192.168.99.1
prefix: 24
nat: false

```

If you use ```wpa_passphrase: ''``` then the created network will be open
- i.e. devices will be able to connect without supplying a passphrase.

## Backlog

- Firewall rules
  - `-N WIFI_OUT`
  - `-N WIFI_IN`
  - `-A FORWARD -i $INTERFACE -j WIFI_OUT`
  - `-A FORWARD -o $INTERFACE -j WIFI_IN`
  - Create a list of rules for each rule:
  - first word should be either IN or OUT
  - -A WIFI_{IN|OUT} ...text of the list item...
  - Clean-up:
  - `-X WIFI_OUT`
  - `-X WIFI_IN`
