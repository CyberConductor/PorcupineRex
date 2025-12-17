docker run -dit \
  --name ubuntu_ho \
  -p 21:21 \
  -p 21000-21010:21000-21010 \
  ubuntu_ho