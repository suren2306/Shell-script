#!/bin/bash
oldname=$(cat /etc/hostname)
newhost="newname"
sudo sed -i "s/$oldname/$newhost/g" /etc/hosts
sudo sed -i "s/$oldname/$newhost/g" /etc/hostname
hostname $newhost