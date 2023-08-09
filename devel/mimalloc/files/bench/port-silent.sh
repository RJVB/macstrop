#!/bin/sh

nohup port -q "$@" < /dev/null > /dev/null
