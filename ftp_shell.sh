docker stop ubuntu_ho || true
docker rm ubuntu_ho || true

docker run -d \
  --name ubuntu_ho \
  -p 21:21 \
  -p 21000-21010:21000-21010 \
  ubuntu_ho
