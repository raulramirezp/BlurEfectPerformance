#!bin/bash

file="blurGPU.out"
if [ ! -f "$file" ] ; then
	# if not create the file
        touch "$file"
else
	read -p "El archivo ya existe, desea sobreescribirlo? : ( s/n ) 	" doit 
	case $doit in  
	  s|S) echo sobreescribiendo... 
	       rm $file
	       touch $file;; 
	  n|N) echo ejecutando... ;; 
	  *) echo Opcion por defecto: no sobreescribir;; 
	esac
fi
echo '\n' >> "$file"

for radio in 3 6 12 15
do
	echo "Kernel, hilos,720p, 1080p, 4k"
	for NumThread in 64 128 256 1024
	do
		printf "$radio, $NumThread, " >> "$file" 	
		time -o "$file" -a -p ./GPU/blur-effect images/720.jpg $radio $NumThread
		printf ", " >>"$file"
		time -o "$file" -a -p ./GPU/blur-effect images/1080.jpg $radio $NumThread
		printf ", " >>"$file"
		time -o "$file" -a -p ./GPU/blur-effect images/4k.jpg $radio $NumThread
		echo >> "$file"
	done
done




