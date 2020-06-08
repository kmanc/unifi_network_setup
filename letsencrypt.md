# Replacing the default cert

#### This part is gonna be shorter with less explanation until / unless it get's to a spot that I want to dedicate more time to. Right now there isn't a great solution for renewals

Install letsencrypt on the cloud key

`apt install letsencrypt`


Run it on your domain

`certbot certonly --manual --preferred-challenges dns -d *.<your_domain>`


Follow instructions and add the DNS TXT record in your registrar's UI


Go to where the certs went

`/etc/letsencrypt/live/<your_domain>`


Move them to where they need to be

`mv *.pem /etc/ssl/private`


Package a pkcs 12 bundle (you'll have to set a password here)

`openssl pkcs12 -export -in fullchain.pem -inkey privkey.pem -out <your_domain>.p12 -name unifi`


Import to the cloud key keystore

`keytool -importkeystore -deststorepass aircontrolenterprise -destkeypass aircontrolenterprise -destkeystore /usr/lib/unifi/data/keystore -srckeystore <your_domain>.p12 -srcstoretype PKCS12 -srcstorepass <your_certificate_password> -alias unifi`


Copy to the filenames nginx wants

`cp fullchain.pem /etc/ssl/private/cloudkey.crt`

`cp privkey.pem /etc/ssl/private/cloudkey.key`


Fix permissions

`chown root:ssl-cert /etc/ssl/private/*`

`chmod 640 /etc/ssl/private/*`


Restart things

`service nginx restart`

`service unifi start`

`reboot now`
