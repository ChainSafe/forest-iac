#!/bin/bash

set -e

## Source forest env variables
source ~/.forest_env

## Start docker daemon
systemctl start docker
