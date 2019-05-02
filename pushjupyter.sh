#!/bin/bash

#This programme configures your google cloud account and pushes your jupyter/minimal-notebook images to google container registry
#This programme needs sudo privileges for somme command pls make sure the user is in sudo group
#./pushjupyter.sh
#Author:Yogesh S.



sudo snap install google-cloud-sdk --classic
echo "Pls give Google cloud account name:" 
read gact
gcloud auth login "$gact"
sudo snap install kubectl --classic
sudo apt install docker.io
mypj=`gcloud config list --format='text(core.project)'|awk -F: '{ print $2 }'|sed "s/^ //g"`
sudo docker pull jupyter/minimal-notebook
sudo docker tag jupyter/minimal-notebook gcr.io/"$mypj"/jupyter/minimal-notebook:latest
sudo gcloud auth configure-docker
sudo docker push gcr.io/"$mypj"/jupyter/minimal-notebook

