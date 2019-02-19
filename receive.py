#!/usr/bin/env python

import select, socket
import subprocess
import os

port = 5559
bufferSize = 1024

s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.bind(('0.0.0.0', port))

while True:
    data, addr = s.recvfrom(1024)
    print "received incoming call info : ", data

