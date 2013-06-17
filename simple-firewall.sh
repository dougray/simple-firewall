#!/bin/sh
#
# name: simple-firewall.sh
# author: jgor <jgor@indiecom.org>
# created: 2010-08-27
#
# This is a generic firewall script. Unsolicited inbound traffic is dropped
# by default, allowing only ports listed in SERVICES_TCP and SERVICES_UDP.
# All outgoing traffic is allowed by default.


# Path to iptables binary
IPT=/sbin/iptables

# Public-facing network interface
EXT=eth0

# Comma-separated list of TCP ports to allow
SERVICES_TCP=22,80,443

# Comma-separated list of UDP ports to allow
SERVICES_UDP=


########## DO NOT EDIT AFTER THIS LINE ##########

do_start() {
  echo -n "Initializing firewall rules...";

  $IPT -P INPUT DROP
  $IPT -P FORWARD DROP
  $IPT -P OUTPUT ACCEPT

  $IPT -A INPUT -i lo -j ACCEPT
  $IPT -A INPUT -i $EXT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

  $IPT -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

  if [ -n "$SERVICES_TCP" ]; then
    $IPT -A INPUT -i $EXT -p tcp -m multiport --dports $SERVICES_TCP -j ACCEPT
  fi

  if [ -n "$SERVICES_UDP" ]; then
    $IPT -A INPUT -i $EXT -p udp -m multiport --dports $SERVICES_UDP -j ACCEPT
  fi

  echo "done.";
}

do_flush() {
  echo -n "Flushing firewall rules...";

  $IPT -F
  $IPT -X
  $IPT -F
  $IPT -X
  $IPT -t nat -F
  $IPT -t nat -X
  $IPT -t mangle -F
  $IPT -t mangle -X
  $IPT -P INPUT ACCEPT
  $IPT -P FORWARD ACCEPT
  $IPT -P OUTPUT ACCEPT

  echo "done.";
}

case "$1" in
  'start' | 'restart')
    do_flush;
    do_start;
  ;;
  'stop')
    do_flush;
  ;;
  *)
    echo "Usage: $0 {start|stop|restart}"
  ;;
esac

