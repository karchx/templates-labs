#!/bin/bash

docker build -t k8s1:latest .

docker save k8s1:latest -o k8s1_image.tar
