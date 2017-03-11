# ghost-stackscript
A Linode Stackscript for Ghost with Nginx on Ubuntu 16.04
Still in development. I plan to have a let's encrypt cert easily installed with it based on input through Linode Manager.

If you enter in a pubkey, this will insert it into root's authorized_keys file and disable password authentication
If you don't enter an FQDN into "website", it'll use "example.com" to finish the ghost installation.

https://www.linode.com/stackscripts/view/72440

