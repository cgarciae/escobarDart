#!/bin/bash
docker stop webDart
docker rm webDart

docker run -d -p 8090:8080 -it --name webDart --link db:db cgarciae/aristadart:0.0.1