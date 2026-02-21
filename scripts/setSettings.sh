#!/bin/bash


#add docker group
sudo groupadd docker

#add user to docker group
sudo usermod -aG docker ho

#change permissions of docker socket
sudo chgrp docker /var/run/docker.sock
sudo chmod 660 /var/run/docker.sock

sudo snap restart docker
#restart the Docker snap service to apply group changes
#reboot the system to ensure all changes take effect and Docker starts correctly

sudo reboot