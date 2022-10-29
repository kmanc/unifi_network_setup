# VPNing to your home


Setting up Wireguard on my USG was much easier than I expected, and allows me to access my network no matter where I am.


## Installation


Unlike OpenVPN, Wireguard is not built-in to the USG. But installation is just a few commands away. SSH in to your USG and run the following commands

```
sudo -i
cd /tmp
curl -o wg.deb -L https://github.com/WireGuard/wireguard-vyatta-ubnt/releases/download/<whatever_current_release_is_there>
dpkg -i wg.deb
```


## Upgrading


Because we're dealing with a user-installed package, we need to make sure we stay on top of updating on our own now; Unifi won't do that for us. I haven't tested this yet as there haven't been new releases, but the documentation says you should run the following commands

```
curl -OL https://github.com/WireGuard/wireguard-vyatta-ubnt/releases/download/<new_release>

configure
set interfaces wireguard wg0 route-allowed-ips false
commit
delete interfaces wireguard
commit
sudo rmmod wireguard
sudo dpkg -i <new_release>.deb
sudo modprobe wireguard
load
commit
save
exit
```


## Server configuration


Now you need to set up the keys and configure the server. First some housekeeping to organize the keys, then create the server public and private keys

```
cd /config/auth
umask 077
mkdir wireguard && cd wireguard
wg genkey | tee server.private | wg pubkey > server.public
wg genkey | tee client1.private | wg pubkey > client1.public
```

Now it's time to set up the USG to act as a Wireguard server. It's pretty similar to the OpenVPN setup, though arguably simpler

```
configure
set interfaces wireguard wg0 address 172.16.0.1/24
set interfaces wireguard wg0 listen-port 51820
set interfaces wireguard wg0 route-allowed-ips true
set interfaces wireguard wg0 private-key /config/auth/wireguard/server.private
set interfaces wireguard wg0 peer <client1.public_contents> allowed-ips 172.16.0.2/32
```

This makes a Wireguard interface on the USG that can server IP addresses in the 172.16.0.1/24 range, instructs the USG to listen on port 51820, and then allows client1 to connect as long as it says it is coming from 172.16.0.2 (more on that in a sec).


## Client configuration


With the Wireguard server set up, you'll need to set up the client. I use the Wireguard client app which I downloaded from the internet, and then clicked the plus sign and "Add Empty Tunnel". Then I filled in the blank file with the following information

```
[Interface]
PrivateKey = <client1.privates_contents>
Address = <an_ip_address_or_range>

[Peer]
PublicKey = <server.publics_contents>
AllowedIPs = <another_ip_address_or_range>
Endpoint = <server_ip_or_domain_name>:51820
```

Now this part tripped me up a bit. Put briefly:
- Interface --> Address defines what IP address the client should say it's coming from. This **must** match the allowed-ips you set up in the server config; in my case 172.16.0.2/32
- Peer --> AllowedIPs defines which destination IP addresses should be sent over the tunnel. If you want all traffic to traverse the tunnel, you can set this to 0.0.0.0/0. I set it to the specific ranges in my network that I expected to reach over the VPN
- Peer --> Endpoint defines where to connect to the VPN. For me, this was my DDNS name...speaking of which


---
[Next up, Dynamic DNS](https://github.com/kmanc/unifi_network_setup/blob/main/docs/dynamicdns.md)
