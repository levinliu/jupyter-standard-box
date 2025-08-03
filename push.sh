# https://docs.docker.com/get-started/publish-your-own-image/
# docker login -u tryd
version=latest
version=20230816
version=20230910v2
# denied: requested access to the resource is denied
docker tag jupyter_standard_box:20230825 tryd/jupyter_standard_box:$version
docker push  tryd/jupyter_standard_box:$version