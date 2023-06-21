#!/bin/bash

## Install Ruby
dnf install -y ruby ruby-devel

## Start benchmark
ruby run_benchmark.rb
