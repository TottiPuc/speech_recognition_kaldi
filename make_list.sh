#!/bin/bash



data=$1
cami=$2

ls $data/*.wav | while read line;
do

cad=$(echo $line | cut -d/ -f10)

len=`expr length $cad`

   if [ $len -ne 12 ]; then
	lin=$(echo $line | cut -d/ -f10 | cut -c 20-31)
	inic=$(echo $line | cut -d/ -f10 | cut -c 20-27)
	echo $lin
	#echo $inic
	if [ "$line" == "$data/$lin" ]; then
                echo $inic $data/$lin>> $2/wav.scp
        else
                mv $line  $data/$lin
                echo $inic $data/$lin>> $2/wav.scp
        fi

#	mv $line  $data/$lin
#	echo $inic $data/$lin>> $2/wav.scp

   else
	lin=$(echo $line | cut -d/ -f10 | cut -c 1-12)
	inic=$(echo $line | cut -d/ -f10 | cut -c 1-8)
	echo $lin
	#echo $inic
	if [ "$line" == "$data/$lin" ]; then
		echo $inic $data/$lin>> $2/wav.scp
	else
		mv $line  $data/$lin
        	echo $inic $data/$lin>> $2/wav.scp
	fi
   fi
done 
