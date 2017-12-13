Introduction
************
My first `tutorial <https://x-vps.com/blog/?p=111>`_ I wrote around August 2017.
Due to the exponential growth of the community and users who want to run their own full node, I thought it is a good time to write a new, more comprehensive tu
torial.

Why Another Tutorial?
=====================

I am hoping this tutorial will come in handy for those who posses less or almost no skills with Linux. And indeed, this tutorial focuses on Linux -- as suggest
ed by many other tutorials (and justifiably), Linux is the best way to go.

I found that many tutorials lack some basic system configuration and explanations thereof. For example, running IRI as an unprivileged user, configuring firewa
lls, how to connect to it remotely and so on.

A copy-paste tutorial is awesome, and as it so often happens, the user can miss on some basic technical explanation about the setup. While it is impossible to
include a crash-course of Linux for the purpose of this tutorial, I will try to explain some basic concepts where I find that many users had troubles with.



Disclaimer
----------
* This tutorial is based on the repository's Ansible-playbook I provided. It has been tested on CentOS 7.4 and Ubuntu 16.04.
* This tutorial does not include information on how to harden security on your server.
* For some details I will leave it to you to google (for example, how to SSH access your server). Otherwise the tutorial becomes too lofty.
* I recommend that you use SSH key authentication to your server, disable root SSH access and disable password authentication. In addition, do not expose firew
all ports if not necessary.
* I am not associated with the IOTA foundation. I am simply an enthusiastic community member.

Feel free to comment, create issues or contact me on IOTA's slack channel (nuriel77) for advice and information.

Good luck!

