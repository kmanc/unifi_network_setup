This repo is about my home network, its setup, and how you can recreate it or a similar one. I learned a lot from trial and error in the processing of building it so I hope to pay it forward with some documentation :)

I tried to lay things out in an order that makes sense if you're starting from scratch, but if you are only interested in a specific aspect just skip ahead. Otherwise this is the order in which I set things up:


### [Unifi](https://kmanc.github.io/unifi_network_setup/unifi.html)
- What I did on the Cloud Key so I could manage the network the way I wanted to. This covers:
  - Creating [network architecture (VLANs)](unifi#setting-up-the-networks-vlans)
  - Creating [firewall rules](unifi#firewall-rules) to enforce the architecture
  - Setting up [Wireguard](unifi#wireguard) for remote access to the network
  - The Unifi part of [DDNS](unifi#ddns), but you'll have to do [some setup on your registrars site as well](#dynamic-dns-with-cloudflare)
  - Adding a [Let's Encrypt certificate](unifi#let's-encrypt) to avoid the annoying warnings about unprotected traffic


### [Proxmox](https://kmanc.github.io/unifi_network_setup/proxmox.html)
- My lab, which has a bunch of VMs on it for different uses


### [Home Assistant](https://kmanc.github.io/unifi_network_setup/homeassistant.html)
- Home assistant on a Raspberry Pi, for flexibility on home automation


### [Dynamic DNS with Cloudflare](https://kmanc.github.io/unifi_network_setup/dynamicdns.html)
- "Name" your home with a domain so you don't have to remember an IP address


## My network


![](/images/network_diagram.svg)


### My network explained

- Modem
  - [ARRIS SB8200](https://www.amazon.com/dp/B07DY16W2Z?th=1)
- VLAN1 (Default)
  - [UXG Max](https://store.ui.com/us/en/pro/category/all-cloud-keys-gateways/products/uxg-max)
  - [Unifi 16 Port PoE Switch](https://store.ui.com/us/en/pro/category/all-switching/products/usw-16-poe)
  - [Unifi Cloud Key Gen 2+](https://store.ui.com/us/en/pro/category/all-cloud-keys-gateways/products/unifi-cloudkey-plus)
  - [U6 Pro Access Point](https://store.ui.com/us/en/pro/category/all-wifi/products/u6-pro)
- VLAN2 (Home)
  - My desktop
  - My laptop
  - My phone
  - SO's desktop
  - SO's laptop
  - SO's phone
- VLAN3 (Guest)
  - Guests who join via [my Raspberry Pi QR Code password generator / sharer](https://kmanc.github.io/wifi_qr/)
- VLAN4 (IoT)
  - Chromecast
  - Google Home
  - Home Assistant Raspberry Pi
  - Printer
  - Smart lights
  - Smart plugs
  - The Raspberry Pi that does the Guest wifi password management
  - Basically any other IoT device
- VLAN5 (Lab)
  - My Proxmox server with a few VMs
- VLAN 244 (Wireguard)
  - Landing spot for my laptop or my phone via Wireguard VPN

In general, VLANs cannot talk to each other, except for the (many) purple arrows:
- My desktop can initiate contact with the Cloud Key, for managing the network
- My laptop can initiate contact with the Cloud Key, for managing the network
- VLAN2 (Home) can initiate contact with the Chromecast, for entertainment
- VLAN2 (Home) can initiate contact with the Home Assistant server, for anything home automation
- VLAN2 (Home) can initiate contact with the Printer, for...printing
- VLAN2 (Home) can initiate contact with VLAN5 (Lab), so I can do stuff on my VMs
- VLAN3 (Guest) can initiate contact with the Chromecast, for entertainment
- VLAN3 (Guest) can initiate contact with the Printer, for printing
- The Raspberry Pi QR Code Bot on VLAN3 can initiate contact with the Cloud Key, for managing the Guest wifi password
- VLAN244 (Wireguard) can initiate contact with VLAN5 (Lab), so I can do stuff on my VMs from the road
