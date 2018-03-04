clear
read -p "Desea ejecutar la versión del blur-effect en GPU (S/N)" doit 
case $doit in  
	s|S) echo "Ejecutandose con un radio de 4 con 1024 hilos"
		./GPU/blur-effect images/720.jpg 4 1024 ;;
	n|N) echo "Ejecutandose con un radio de 4 con 4 hilos"
		./Posix/blur-effect images/720.jpg 4 4
		echo "Ejecutandose con un radio de 4 con 4 hilos en OpenMP"
		./OMP/blur-effect images/720.jpg 4 4;;
	*) echo Opcion no valida;; 
esac
echo "La imagen a sido guardada en el directorio superior al actual como thread_blur.jpg"
