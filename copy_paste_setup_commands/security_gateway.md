## Initial bugfix


```
configure
set service dhcp-server shared-network-name LAN_192.168.1.0-24 subnet 192.168.1.0/24 default-router 192.168.1.1
set service dhcp-server shared-network-name LAN_192.168.1.0-24 subnet 192.168.1.0/24 dns-server 192.168.1.1
commit
save
exit
```


## Wireguard install


```
sudo -i
cd /tmp
curl -o wg.deb -L https://github.com/WireGuard/wireguard-vyatta-ubnt/releases/download/CURRENT_RELEASE
dpkg -i wg.deb
```


## Wireguard config


```
cd /config/auth
umask 077
mkdir wireguard && cd wireguard
wg genkey | tee server.private | wg pubkey > server.public
wg genkey | tee CLIENT1_NAME.private | wg pubkey > CLIENT1_NAME.public
configure
set interfaces wireguard wg0 address DESIRED_VPN_RANGE
set interfaces wireguard wg0 listen-port 51820
set interfaces wireguard wg0 route-allowed-ips true
set interfaces wireguard wg0 private-key /config/auth/wireguard/server.private
set interfaces wireguard wg0 peer CLIENT1_PUBLIC_KEY_CONTENTS allowed-ips CLIENT1_DESIRED_IP
commit
save
exit
mca-ctrl -t dump-cfg > config.gateway.json
```