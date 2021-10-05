# Wireguard to your home


Setting up Wireguard on my USG was much easier than I expected, and allows me to access my network no matter where I am.


## Installation


Unlike OpenVPN, Wireguard is not built-in to the USG. But installation is just a few commands away. SSH in to your USG and run the following commands

```
sudo -i
cd /tmp
curl -o wg.deb -L https://github.com/WireGuard/wireguard-vyatta-ubnt/releases/download/<whatever_current_release_is_there>
dpkg -i wg.deb
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


## Making the changes stick


So far so good, your USG is now an Wireguard server that your client can connect to! The only problem is that the next time your USG provisions, it will clear all the work you did. Enter "config.gateway.json", which is basically a way to manage all of the Unifi options that the UI doesn't support. While on the USG, run the following command.

```
mca-ctrl -t dump-cfg > /tmp/config.gateway.json
```


That saves your current configuration to a file on the USG, but you'll need to move it to the controller to actually have it apply. I used SCP to move it to the controller's "/tmp" directory. Once it is on the controller, SSH into that and run the following.


```
mv /tmp/config.gateway.json /srv/unifi/data/sites/default
chown unifi:unifi /srv/unifi/data/sites/default/config.gateway.json
```


If the directory above doesn't exist you'll have to create it, but once you've done that you're all set! Even provisions won't stop your Wireguard abilities now.


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


## Dynamic DNS (DDNS)


If you have a domain like I did for my peer endpoint, for bonus points you can set up Dynamic DNS for OpenVPN purposes. Here's the problem; although it doesn't happen often, your public IP address could change at any time. If it changes, you won't know where to point your OpenVPN client config file. This is where DDNS can help. You can tell your USG to tell your registrar what it's IP address is, make your domain point to that IP address, and update it if it ever changes. Then in your client OpenVPN config, you can replace your IP address with the domain so that no matter what happens your VPN will always point back to your USG. Setting it up on your registrar is usually pretty easy, and configuring your USG to do it is pretty simple too (though the way Unifi names things is weird so for some registrars it's not really intuitive).


First set up DDNS with your registrar for your domain. Then, from the controller UI click "Settings", "Advanced Features", "Advanced Gateway Settings". Then select "Create a New Dynamic DNS". Fill out the form as seen in the image below. Normally this is straightforward, but for my registrar (Namecheap), things get funky. The "Username" field is actually my domain, which I find super confusing. Also with most registrars you leave the "Server" field blank, but with Namecheap you need to add that one. I don't know why, but hey it works so I guess I shouldn't complain.


![](images/ddns.png)