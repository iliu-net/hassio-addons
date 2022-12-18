#!/bin/bash

CONFIG_PATH=/data/options.json

#
# Determine which version of IPTABLES to use
#
if [ $(iptables -L --line-numbers | grep -E '^[0-9]' | wc -l) -gt $(iptables-nft -L --line-numbers | grep -E '^[0-9]' | wc -l) ] ; then
  # the assumption is that there are always rules present (i.e. for docker)
  iptablesV=iptables
else
  iptablesV=iptables-nft
fi



INTERFACE=$(jq --raw-output ".interface" $CONFIG_PATH)
SSID=$(jq --raw-output ".ssid" $CONFIG_PATH)
WPA_PASSPHRASE=$(jq --raw-output ".wpa_passphrase" $CONFIG_PATH)
CHANNEL=$(jq --raw-output ".channel" $CONFIG_PATH)
ADDRESS=$(jq --raw-output ".address" $CONFIG_PATH)
PREFIX=$(jq --raw-output ".prefix" $CONFIG_PATH)

START_RANGE=$(jq --raw-output ".start_range" $CONFIG_PATH)
END_RANGE=$(jq --raw-output ".end_range" $CONFIG_PATH)

NAT=$(jq --raw-output ".nat" $CONFIG_PATH)
DNS=$(jq --raw-output ".dns" $CONFIG_PATH)

STATIC_IPS=$(jq --raw-output ".static_ips" $CONFIG_PATH)

# Make sure config is complete
for required_var in INTERFACE SSID CHANNEL ADDRESS PREFIX
do
  if [[ -z ${!required_var} ]]; then
    error=1
    echo >&2 "Error: $required_var env variable not set."
  fi
done
[ -n "$error" ] && exit $error

# Make sure the Interface exists...
if [ ! -e "/sys/class/net/$INTERFACE" ] ; then
  for nic in $(ls -1 /sys/class/net)
  do
    [ ! -e "/sys/class/net/$nic/address" ] && continue
    if [ x"$(echo "$INTERFACE" | tr A-Z a-z)" = x"$(cat /sys/class/net/$nic/address)" ] ; then
      INTERFACE="$nic"
      break
    fi
  done
fi
if [ ! -e "/sys/class/net/$INTERFACE/wireless" ] ; then
  echo "$INTERFACE: wireless interface not found"
  exit 1
fi

gen_static_ips() {
  local row hname mac ip
  for row in $(echo "$*" | jq -r '.[] | @base64')
  do
    hname=$(echo "${row}" | base64 -d | jq -r .name)
    mac=$(echo "${row}" | base64 -d | jq -r .mac)
    ip=$(echo "${row}" | base64 -d | jq -r .ip)
    echo "host $hname  { hardware ethernet $mac; fixed-address $ip;}"
  done
}

# Clean-up function
term_handler(){
  echo "Stopping..."
  if $NAT ; then
    echo "Removing IPTABLE rules"
    $iptablesV -t nat -D POSTROUTING -s $NETWORK/$PREFIX -j MASQUERADE
    $iptablesV -D FORWARD -i $INTERFACE -s $NETWORK/$PREFIX -j ACCEPT
    $iptablesV -D FORWARD -o $INTERFACE -d $NETWORK/$PREFIX -j ACCEPT

  fi

  kill $(cat /var/run/dhcp/dhcpd.pid)

  ip link set $INTERFACE down
  ip addr flush dev $INTERFACE
}

# Setup signal handlers
trap 'term_handler' EXIT

echo "Starting..."
echo "Configuring hostapd.conf"
if [ -n "$WPA_PASSPHRASE" ] ; then
  WPA_SETTINGS="
auth_algs=1
wpa=2
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
wpa_passphrase=$WPA_PASSPHRASE"
else
  echo "WARNING: no passphrase configured so creating an open access point"
fi
cat >/etc/hostapd.conf <<-_EOF_
	# 2.4GHz n wifi
	hw_mode=g
	ieee80211n=1
	driver=nl80211

	# WMM
	wmm_enabled=0

	# Enable 40MHz channels with 20ns guard interval
	ht_capab=[HT40][SHORT-GI-20][DSSS_CCK-40]

	# No MAC restriction
	macaddr_acl=0

	# Require clients to know the network name
	ignore_broadcast_ssid=0

	# Configure log
	logger_stdout=16
	logger_stdout_level=4

	interface=$INTERFACE
	channel=$CHANNEL
	ssid=$SSID

	$WPA_SETTINGS

	_EOF_


# Setup interface
echo "Setup interface ..."

ip link set $INTERFACE down
ip addr flush dev $INTERFACE
ip addr add ${ADDRESS}/$PREFIX dev $INTERFACE
ip link set $INTERFACE up

# Setup interface
echo "Setup dhcp ..."

[ -z "$DNS" ] && DNS="$ADDRESS"

eval $(ipcalc -bnm $ADDRESS/$PREFIX)

cat > /etc/dhcp/dhcpd.conf <<-ENDFILE
	option domain-name-servers $DNS;

	default-lease-time 600;
	max-lease-time 7200;

	authoritative;

	subnet $NETWORK netmask $NETMASK {
	     #option domain-name "wifi.localhost";
	     option routers $ADDRESS;
	     option subnet-mask $NETMASK;
	     option broadcast-address $BROADCAST;
	     option domain-name-servers $DNS;
	     range dynamic-bootp $(echo $NETWORK | cut -d. -f 1-3).$START_RANGE $(echo $NETWORK | cut -d. -f 1-3).$END_RANGE;
	     group {
	       $(gen_static_ips "$STATIC_IPS")
	     }
	}
	ENDFILE

if $NAT ; then
  echo "Adding IPTABLES rules"
  set -x
  $iptablesV -t nat -A POSTROUTING -s $NETWORK/$PREFIX -j MASQUERADE
  $iptablesV -A FORWARD -i $INTERFACE -s $NETWORK/$PREFIX -j ACCEPT
  $iptablesV -A FORWARD -o $INTERFACE -d $NETWORK/$PREFIX -j ACCEPT
  set +x
fi

echo "Starting dhcpd daemon ..."
touch /var/lib/dhcp/dhcpd.leases
dhcpd -d -pf /var/run/dhcp/dhcpd.pid -cf /etc/dhcp/dhcpd.conf $INTERFACE &

echo "Starting HostAP daemon ..."
hostapd -d /etc/hostapd.conf
