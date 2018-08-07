# centos-server-build
CentOS-based Linux server that can serve as a LAMP server

## Installation
* Install a fresh copy of CentOS 7
* Log in with root
* Create a new user account
```bash
adduser newuser
```
* Change the user's password
```bash
passwd newuser
```
* Add the user to the _wheel_ group (so they can sudo)
```bash
usermod -aG wheen newuser
```
* Harden the server with https://github.com/massyn/centos-cis-benchmark
* Do a full update
```bash
yum -y update
```
* Do a reboot so the latest settings can kick in
```bash
reboot
```
* Install the scripts
```bash
git clone https://github.com/massyn/centos-server-build
cd centos-server-build
sudo bash install.sh
```
