## User administration


```
sudo passwd ubnt
sudo useradd -m DESIRED_USERNAME
sudo passwd DESIRED_USERNAME
sudo usermod —shell /bin/bash DESIRED_USERNAME
sudo usermod -a -G sudo DESIRED_USERNAME
```


## config.gateway.json persistence


```
sudo mkdir -p /usr/lib/unifi/data/sites/default
sudo mv /tmp/config.gateway.json /usr/lib/unifi/data/sites/default
sudo chown unifi:unifi /usr/lib/unifi/data/sites/default/config.gateway.json
```
