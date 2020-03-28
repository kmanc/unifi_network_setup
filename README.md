# OpenVPN server on your Unifi USG

This repo will only be a readme, but will walk through all of the steps that I took to run an OpenVPN server on my Unifi USG so that I could connect to my home network from anywhere in the world. Some of the documentation of these things is outdated and/or unclear, so I hope this helps if you are looking to set up a similar way to connect back home. I learned by trial-and-error and I took some steps that you might feel are a little over-the-top, so feel free to tone down to suit your preference :)

### Step 1 - the certificate authority (CA)
I chose to use a Raspberry Pi as my certificate authority machine. Generally speaking it is best practice to not have your CA be the same machine that runs the OpenVPN server, and since it is really easy to get a small SD card, set up the certificates, and then move the SD card to a safe-keeping place, I did just that! All you really need is a Linux machine capable of installing easy-rsa to do things the way I did, so without further ado, here are the commands I ran. 

```
sudo apt install easy-rsa
sudo apt install openvpn
cd /usr/share/easy-rsa
sudo cp vars.example vars
sudo nano vars
  * change the set_var organizational fields to your liking
  * change the key size to 4096 (this isn't necessary, but was one of the security choices I made)
sudo ./easyrsa init-pki
sudo ./easyrsa build-ca
  * Common Name: openvpn_ca
  * set a password as you see fit for the certificate authority key
sudo ./easy-rsa build-server-full server nopass
sudo ./easy-rsa build-client-full <client_name>
  * set a password as you see fir for the client key
sudo ./easy-rsa gen-dh
sudo mv dh.pem dh4096.pem (4096 here is the same size as my key choice from above; is yours is different, use your key size)
sudo openvpn --genkey --secret ta.key (this is another step that you don't technically need, but I chose to include)
sudo mv ta.key pki/
sudo cp -r pki/ /tmp/openvpn
cd /tmp/openvpn
sudo cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf .
sudo nano client.conf
	* add a line that say "float" to allow for IP negotiation when your client connects
	* change "remote" server to the IP or DNS you intend to connect to
	* uncomment the user and group downgrades for linux (not needed, but I chose to)
	* change the SSL/TLS params to /<path>/<build-client-full names>
	    * the path is where you will host the files on your client machine... for instance you might set them to /openvpn/client.crt, /openvpn/ca.crt, etc
	* change the tls-auth to /openvpn_files/ta.key (this is only necessary if you chose to generate a ta.key like I did above)
	* add a line that reads auth SHA256 (this is not necessary, and will default to SHA1 if you don't)
sudo mv client.conf client.ovpn
```

And just like that you're done with your CA! You'll have to do some file movement though, so however you normally do that (for me it's SCP) is up to you. Make sure you put the client files in the path you reference in your client.ovpn, and your server files in the path you mention in the server configuration (step 2 - below)

Your VPN client will need:
* ca.crt
* client.crt
* client.key
* client.ovpn
* ta.key (if you created it)

Your VPN server will need:
* ca.crt
* dh<####>.pem
* server.crt
* server.key
* ta.key (if you created it)

A notes on step 1 in case you were interested:
* The dh<####>.pem (Diffie-Hellman) you created determines how your server and client will exchange keys - I default to using a higher key size than necessary. It will take longer, but is mostly a one-time cost
* The ta.key file is a way to harden the security of an OpenVPN configuration. If the client and server don't have the correct ta.key, traffic will be dropped during the SSL/TLS handshake (early enough in the connection that a few categories of attacks become unfeasible)

### Step 2 - the OpenVPN server
Like I mentioned above, my OpenVPN server will be my Unifi USG. Because OpenVPN is not something you can use the GUI for, we'll start by SSHing into the USG, and running the following commands (I've put some comments in lines starting with "#", don't enter those)

```
sudo bash
configure
edit interfaces openvpn vtun0
# Tell the interface to act as a server
set mode server
set description OpenVPN
set encryption aes256
# Only do the next step if you added "auth SHA256" to your client ovpn
set hash sha256
# Chose any private IP subnet you like, but this one tends to avoid collisions in my experience
set server subnet 172.16.0.0/24
# I chose to add a path for my VPN client to reach machines on my 192.168.1.0/24 subnet. You may or may not care to do this step
set server push-route 192.168.1.0/24
set server name-server 192.168.1.1
set tls ca-cert-file /config/auth/ca.crt
set tls cert-file /config/auth/server.crt
set tls key-file /config/auth/server.key
# Make sure you fill in the number that you've been using for DH so far
set tls dh-file /config/auth/dh####.pem
# Only add this if you created the ta.key and gave it to the client and server
set openvpn-option "--tls-auth /config/auth/ta.key 0"
set openvpn-option "--user nobody"
set openvpn-option "--group nogroup"
set openvpn-option "--port 1194"
top
# Don't change the name of this rule or you might get unexpected behavior
edit firewall name WAN_LOCAL
# The rule number doesn't have to be 1, I just chose 1 because it was easy
set rule 1 action accept
set rule 1 description "OpenVPN on IPv4 allowed from internet"
set rule 1 destination port 1194
# You can log things if you want, but I didn't
set rule 1 log disable
set rule 1 protocol udp
top
# Same notes apply here that applied to the WAN_LOCAL rule above
edit firewall ipv6-name WANv6_LOCAL
set rule 1 action accept
set rule 1 description "OpenVPN on IPv6 allowed from internet"
set rule 1 destination port 1194
set rule 1 log disable
set rule 1 protocol udp
top
# This next part only matters if you want your client to be able to reach the open internet once it is connected; if you don't, skip to the commit line a few below
edit service nat rule 5001
set description "Masquerade for OpenVPN to WAN"
set outbound-interface eth0
set type masquerade
top
commit
exit
# This next line doesn't have to be run, but when you're logged in to the USG it will show you what (if any) clients are connected
show openvpn status server
# This line will set you up such that your USG won't lose its configuration on provision/reboot
mca-ctrl -t dump-cfg > /tmp/config.gateway.json
```

### Step 3 - making the changes stick
Like I mentioned in the last command in step 2, you've started to lay the groundwork for having this change be persistent, but right now it isn't. If you reboot or reprovision your USG now, the config you made will be lost. To fix that, start by moving the config.gateway.json file from your USG to your network controller (in my case, a Cloud Key). I used SCP, but you can use whatever you normally use. Then SSH into your controller, and run the following

```
mv <path>/config.gateway.json /srv/unifi/data/sites/default
chown unifi:unifi /srv/unifi/data/sites/default/config.gateway.json
```

And that's it! Provision your USG just to verify, but now you should be able to OpenVPN back to home from your client. For me that means running `sudo openvpn client.ovpn` and then typing in the password to my client's key file, but for you that might meaning a GUI or some other method. If you're interested in further reading, or which places I pieced together to get my stuff up and running, here are some reference materials.

##### Step 1
  * https://openvpn.net/community-resources/how-to/

##### Step 2
  * https://www.youtube.com/watch?v=LTBE8YiPhkg
  * https://community.ui.com/questions/OpenVPN-Setup-and-Configuration-on-UniFi-Security-Gateway-Step-by-Step-Guide/2a12e083-03fe-47de-be21-36e7cbba6ccb
  * http://www.forshee.me/2016/03/16/ubiquiti-edgerouter-lite-setup-part-5-openvpn-setup.html
  * https://community.ui.com/questions/How-To-OpenVPN-Server-Configuration-on-the-USG/ce26860f-c0f1-4158-aa27-f8a68a09b4de

##### Step 3
  * https://community.ui.com/questions/USG-that-is-adopted-by-controller-does-not-keep-changes-made-in-CLI-once-rebooted/a72389cb-bce4-448f-b834-137187884bac
