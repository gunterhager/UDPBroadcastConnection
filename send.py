#!/usr/bin/env python

from socket import *
import os, sys

if len(sys.argv) < 3:
    print "usage : sys.argv[0] port message"
    sys.exit(1)

port = int(sys.argv[1])
message = sys.argv[2]

s = socket(AF_INET, SOCK_DGRAM)
s.setsockopt(SOL_SOCKET, SO_REUSEADDR, 1)
s.setsockopt(SOL_SOCKET, SO_BROADCAST, 1)

s.sendto(message, ('255.255.255.255', port))
