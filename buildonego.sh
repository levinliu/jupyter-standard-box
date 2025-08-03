#!/usr/bin/env bash
set -x
dockerFile=./Dockerfile
tagVersion=latest
tagVersion=20240102
tag=jupyter_standard_box:$tagVersion
containerName=jupyter_standard_box
#show build verbose log
docker build --progress=plain -f $dockerFile -t $tag .
if [ "$?" -ne 0 ] ; then
  echo "fail to build image, stop here"
  exit -1
fi
echo "built ${dockerFile} as image ${tag}"
echo  "complete build"

cCount=$(docker ps -a|grep $containerName|wc -l)
if [ $cCount -gt 0 ] ; then
  echo "will stop existing container $containerName"
  docker ps -a|grep $containerName|awk -F" " '{print $1}'| xargs docker rm -f
fi

port=8080
port2=8084
startCmd="docker run -p 15080:$port -p 15064:$port2   -v  notebook:/app/notebook --mount type=bind,source=$(pwd)/notebook,target=/tmp/  --name $containerName -d $tag"
echo "run it:"
echo  "$startCmd"
eval $startCmd
sleep 5
curl localhost:$port
execCmd="docker exec -it  $containerName  bash"
echo  "$execCmd"
echo "start health check"
eval $execCmd