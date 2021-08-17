# Replacing the default cert [(this helped)](https://community.ui.com/questions/Installing-SSL-certs-on-unifi-os-Working-perfectly-2-0-24-unifi-os-easy-way/9c80139d-62b7-419c-896f-f016f2f3cf82) 
Important bit from the link 
```
FYI the configuration for 2.0.x appears to be at:

/usr/share/unifi-core/app/config/config.yaml

In that it references the the crt and key stored at:

/data/unifi-core/config/unifi-core.crt

/data/unifi-core/config/unifi-core.key

You can either backup then replace those files, or modify the config file to point somewhere else.

I went with the former and it works fine for me :)
```

#### This part is gonna be shorter with less explanation until / unless it get's to a spot that I want to dedicate more time to. Right now there isn't a great solution for renewals

Install letsencrypt on the cloud key or machine of choice (I chose my macbook)

`apt install letsencrypt`

`brew install certbot`


Run it on your domain

`certbot certonly --manual --preferred-challenges dns -d "*.<your_domain>"`


Follow instructions and add the DNS TXT record in your registrar's UI

* You can check with `dig _acme-challenge.<your_domain> txt`


Wait a sec, then confirm the certbot CLI as per request


Go to where the certs went or SCP them to your CloudKey

`/etc/letsencrypt/live/<your_domain>`

`sudo scp /etc/letsencrypt/archive/<your_domain>/privkey.pem user@X.X.X.X:/`

`sudo scp /etc/letsencrypt/archive/<your_domain>/fullchain.pem user@X.X.X.X:/`

`sudo scp /etc/letsencrypt/archive/<your_domain>/chain.pem user@X.X.X.X:/`

`sudo scp /etc/letsencrypt/archive/<your_domain>cert.pem user@X.X.X.X:/`


Move them to where they need to be

`mv *.pem /data/unifi-core/config/cert_components`


Package a pkcs 12 bundle (you'll have to set a password here)

`openssl pkcs12 -export -in fullchain.pem -inkey privkey.pem -out <your_domain>.p12 -name unifi`


Import to the cloud key keystore

`keytool -importkeystore -deststorepass aircontrolenterprise -destkeypass aircontrolenterprise -destkeystore /usr/lib/unifi/data/keystore -srckeystore <your_domain>.p12 -srcstoretype PKCS12 -srcstorepass <your_certificate_password> -alias unifi`


Copy to the filenames unifi-core wants

`cp fullchain.pem /data/unifi-core/config/unifi-core.crt`

`cp privkey.pem /data/unifi-core/config/unifi-core.key`


Fix permissions

`chmod 640 /data/unifi-core/config/unifi-core.*`

Restart things

`reboot now`
