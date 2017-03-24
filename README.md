# ghost-stackscript
A Linode Stackscript for Ghost with Nginx on Ubuntu 16.04
THIS IS A WORK IN PROGRESS. Please allow 10 minutes for it to finish installation. Monitor for when it completes in your Lish console.

If you enter in a pubkey, this will insert it into root's authorized_keys file and disable password authentication
If you don't enter an FQDN into "website", it'll use "example.com" to finish the ghost installation.

If you plan on using HTTPS, make sure that your domain is currently resolving on the internet. You can check by running this command:

host example.com

If that returns your Linode's IP address, this StackScript will be able to successfully make a Let's Encrypt cert for you and install it.

https://www.linode.com/stackscripts/view/72440

