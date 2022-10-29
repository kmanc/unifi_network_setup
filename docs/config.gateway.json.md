# Making the changes persist


If you've been following along, hopefully you've got your network just the way you like it, congrats! The only problem is that the next time you provision your USG, you'll likely lose some of the changes you made, specifically around Wireguard. Enter "config.gateway.json", which is basically a way to manage all of the Unifi options that the UI doesn't support. While on the USG, run the following command.

```
mca-ctrl -t dump-cfg > /tmp/config.gateway.json
```


That saves your current configuration to a file on the USG, but you'll need to move it to the controller to actually have it apply. I used SCP to move it to the controller's "/tmp" directory. Once it is on the controller, SSH into that and run the following.


```
mv /tmp/config.gateway.json /usr/lib/unifi/data/sites/default
chown unifi:unifi /usr/lib/unifi/data/sites/default/config.gateway.json
```


If the directory above doesn't exist you'll have to create it, but once you've done that you're all set! Provisions will now apply not only the configuration changes made in the UI, but also those made directly on the USG.