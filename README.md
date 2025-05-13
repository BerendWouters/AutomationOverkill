# AutomationOverkill
This repository describes the homelab and related configurations.
Since I rely on docker to host my services, a lot of these configurations exist in the form of a docker-compose file.

## Hardware
Originally I was running the homelab on a second hand HTPC, with a small SSD (120GB) and a couple of USB hard disks attached. This did work, but was far from perfect. Powerfailures and USB hard disks aren't a good match, and the system in itself wasn't that powerful, yet powerhungry.

So, after a year or so, I decided to replace that system with a new configuration. The goal was to have a large storage disk, enough oomph (but that wasn't actually an issue with the old system) but also power efficient. So, after a lot of research (thanks to the guys at [Het grote zuinige server topic on Tweakers.net](https://gathering.tweakers.net/forum/list_messages/2096876)) I came up with the following setup:
* Intel Core i3-9100 Boxed
* Fujitsu D3643-H
* Kingston ValueRAM KVR26N19D8/16
* Lexar NM710 2TB
* Toshiba MG09 (SATA, Standard, 512e), 18TB
* Silverstone Milo ML04B USB 3.0
* Mini-box PicoPSU-90

## Operating system
Ubuntu Server 24.04 LTS

## Software
As mentioned above, I prefer to run my applications in docker containers. I started out with a [Portainer](https://portainer.io) instance, which allowed me to write my docker compose files in their stack editor. After a couple of months, I did switch to move the docker-compose files to this repository, giving me a bit more security on continuity and failures.
At first the docker images had hardcoded tags assigned, including the random `:latest` tag, which could cause unexpected upgrades. 

## Docker compose files
- Traefik proxy
- Automation tooling
- Metric collection
- Internal networking

## Collection
- Automate SD card copy to other location


## Additionals
- Raspbian by default doesn't support exfat. You might want to follow [this tutorial](https://pimylifeup.com/raspberry-pi-exfat)
     - In short:
     `sudo apt install exfat-fuse exfat-utils`
