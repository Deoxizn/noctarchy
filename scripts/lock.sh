#!/bin/bash
# noctarchy-lock — lock screen + power off monitors after 20s

noctalia msg session lock 2>/dev/null

# Power off monitors after 20s
sleep 20
niri msg action power-off-monitors 2>/dev/null
