#!bin/bash

file="blur.out"
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
echo *----------------------------------------------------------* >> "$file"

for radio in 3 6 12 15
do
	for NumThread in 2 4 8 16
	do
		echo *----------------------------------------------------------* >> "$file"
		echo "Resultados version parallela con $NumThread hilos" >> "$file" 	

		echo "Tiempo para imagen de 720p con un radio de $radio" >> "$file"
		time -o "$file" -a -p ./Posix/blur-effect images/720.jpg $radio $NumThread

		echo "Tiempo para imagen de 1080p con un radio de $radio" >> "$file"
		time -o "$file" -a -p ./Posix/blur-effect images/1080.jpg $radio $NumThread

		echo "Tiempo para imagen de 4k con un radio de $radio" >> "$file"
		time -o "$file" -a -p ./Posix/blur-effect images/4k.jpg $radio $NumThread
	done
done



