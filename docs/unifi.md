# General Unifi setup


> **Warning:** There was a time where sometimes Unifi devices had a nasty bug from fresh install. If it comes back, [see this to fix it](https://community.ui.com/questions/USG-not-advertising-default-gateway/08ac3059-d4b0-4860-889c-d69c1bd3e7e4)


First thing's first, the cloud key needs a name


![](images/unifi_ui/00_name_cloud_key.png)


After a little while of setup, the portal will be ready


![](images/unifi_ui/01_set_up_cloud_key.png)


I can't exactly remember the sequence of events, but I think this page either popped up or I was directed to a Unifi setup page that looked like this


![](images/unifi_ui/02_manage_gateway.png)


Now the Cloud Key is set up and you can log in to really get going


![](images/unifi_ui/03_log_in_to_cloud_key.png)


I like to make sure that all the devices get adopted to the Cloud Key before doing anything else - if they don't a factory reset of the device or some other troubleshooting may be in order


![](images/unifi_ui/04_adopt_all_devices.png)


With all that done, it's time to build the network(s) to your liking. My setup is outlined below.


## Setting up controller portal access


I chose to give my Ubiquity account local credentials to log in to my controller, which I use the majority of the time. I also created another local-only account for my Wifi QR Code project - see [its repo](https://github.com/kmanc/wifi_qr) for details. 


To do this, first click "OS Settings" tab from the main controller login page, followed by "Admins & Users". In the top right there should be a "+" sign for adding an account - click that.


![](images/unifi_ui/05_create_local_account.png)


Now create / edit the local account to your liking.


![](images/unifi_ui/06_account_creation_continued.png)


## Setting up device SSH access


While here, I enabled SSH for my devices because I knew I'd need it later. Under "Console Settings" there is a tick box for SSH.


![](images/unifi_ui/07_account_creation_continued.png)


## Setting up the networks (VLANs)


Now I got to work building out the networks that I knew I would want. In general I created one network for each VLAN I knew I wanted, and enabled a wifi network on the ones where devices would need to be able to connect via wifi. Under the "Network" tab, "Settings" (the gear), and then "Networks" again I created my networks.


![](images/unifi_ui/08_create_first_network.png)


![](images/unifi_ui/09_network_creation_continued.png)


Next up were the wifi networks, as needed.


![](images/unifi_ui/10_create_first_wifi.png)


Repeat as necessary to get your desired results.


> **Note:** If you plan on setting up Wireguard like I did, don't make your Wireguard VLAN here or you'll have to delete it later. I don't think this is the most intuitive setup, but that's just me.


## Firewall rules


In order to prevent devices that don't need connectivity to actually be able to reach each other, I prefer firewall rules to Unifi's "Traffic Rules". They create firewall rules under the hood but don't work intuitively if you ask me.


The first thing I did was plan out the IP groups I would need. These will be static assignments for devices that will have rules applied to them. Also an RFC 1918 group is helpful for preventing VLAN <--> VLAN traffic unless otherwise specified. My RFC 1918 group is shown here, but I created a bunch more for other devices.


![](images/unifi_ui/11_rfc_1918_group.png)


Then actually creating the rules gets the desired network architecture. I create the RFC 1918 rule first to drop VLAN <--> VLAN by default, but then every exception that I create gets placed above it because firewalls only match the first rule that applies


![](images/unifi_ui/12_firewall_rule.png)


## Static assignments


Then I go into the "Unifi Devices" and "Client Devices" pages and make all the static IP assignments I defined in my Firewall's IP groups. Sometimes I add local DNS records as well (shown here).


[](images/unifi_ui/13_controller_hostname.png)


## Wireguard


Wireguard is now supported natively on Unifi! This is pretty awesome, and pretty easy to set up. Under "Settings" (gear), "VPN", I created a Wireguard server and gave it a DNS name that I will later set up Dynamic DNS (DDNS) for. I also had to define the Wireguard VLAN _here_.


[](images/unifi_ui/14_wireguard_server_setup.png)


After that it's just a matter of clicking through client setup options and copying the resulting config file(s) over to the client(s)


[](images/unifi_ui/15_wireguard_client_setup.png)


## DDNS


Setting up DDNS on the Unifi side is <easy??>


[](images/unifi_ui/16_WIP_DDNS.png)


---
[Next up, Proxmox](https://kmanc.github.io/unifi_network_setup/proxmox.html)