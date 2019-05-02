#!/bin/bash
#This programme starts jupyter app on kubernetes cluster in google cloud
# ./launch_jupyter.sh --cpu=[1,2,[10mi,20mi...] --memory=[20mi,30mi.....]

podlog="pods.log"
podtmpl="podcreate"
podexpose="podexpose"
gcmd=`which gcloud`
kbcmd=`which kubectl`

if [ $# -lt 3 ]; then
	echo -e "\t\t ./launch_jupyter.sh --cpu=[1,2,[10m,20m...] --memory=[20mi,30mi.....] --client=[clientname]
		 --cpu=Pls give cpu in units for eg.(1,2,3...etc) or in millicores for eg. ( 10m,20m,30m...etc)
		 --memory=[20mi,30mi.....etc] 
		 --client=[clientname]"
exit
fi
[ ! -f "$podtmpl" ] && echo -e "Template file $podtmpl doesnt exist" && exit
[ ! -f "$podexpose" ] && echo -e "Expose template file $podexpose doesnt exist" && exit
[ ! -x "$gcmd" ] && echo -e "gcloud binary missing" && exit 
[ ! -x "$kbcmd" ] && echo -e " kubectl binary doesnt exist" && exit


mypj=`gcloud config list --format='text(core.project)'|awk -F: '{ print $2 }'|sed "s/^ //g"`
cpu=`echo $1|awk -F= '{ print $2 }'`
memory=`echo $2|awk -F= '{ print $2 }'`
client=`echo $3|awk -F= '{print $2 }'`
clyaml="pod-$client.yaml"
clexpose="podexpose-$client.yaml"
srvname="jy-$client"

#echo $cpu
#echo $memory
#echo $client
#echo $mypj

sed -e "s/jy-CLIENT/$srvname/g" $podtmpl|sed -e "s/PJNM/$mypj/g"|sed -e "s/CPUCORES/$cpu/g"|sed -e "s/MEMORYCOUNT/$memory/g" > $clyaml

( echo `date +"%d-%m-%y %H:%M:%S "`|sed -z 's/\n/ /g' && \
$kbcmd  create -f ./$clyaml )  &>>$podlog
##(echo `date +"%d-%m-%y"`|sed -z 's/\n/ /g' && `kubectl create -f pod_oracle.yaml` ) &>pods.log


#podstat=`tail -n1 "$podlog"|egrep "[ ]created$"`
tail -n1 "$podlog"
podstat=`tail -n1 "$podlog" | egrep -o "\W+created$"|tr -d " "`
if [ "$podstat" = "created" ]; then
sed -e "s/jy-CLIENT/$srvname/g" $podexpose > $clexpose
( echo `date +"%d-%m-%y %H:%M:%S "`|sed -z 's/\n/ /g' && \
$kbcmd create -f ./$clexpose ) &>>$podlog
tail -n1 "$podlog"
echo -e "Sleeping for 60 seconds to get external url ready" && sleep 60
( echo -e "`date +"%d-%m-%y %H:%M:%S "` $srvname http://`$kbcmd get service $srvname  -o json |jq -r '.status[].ingress[].ip'`" ) &>>$podlog
tail -n1 "$podlog"
fi

