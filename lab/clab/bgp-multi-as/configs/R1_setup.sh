#!/bin/bash
# R1 - just bring up lo, frr.conf handles 2.2.2.2 static route
# (kernel 'ip route' gets cleared by frr zebra on startup, so
# static route MUST be in frr.conf for it to persist)
sleep 2
ip link set lo up
echo "R1 ready"
