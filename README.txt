1. Requerimientos

   1.1 Sistema operativo GNU/Linux, recomendamos Ubuntu o Debian
   1.2 Para compilar este programa se requiere como minimo la version 2.8 de OpenCV, si no la tiene instalada la puede descargar desde su sitio oficial http://opencv.org/ e instalarlo como Opencv especifica.
   1.3 Se requiere la versión de CUDA 8.0, o superior.
1. Para compilar el programa ejecute el siguiente comando                                                                                                                                
	
	sh buildAll.sh
	
2. Para correr ejecute el comando                                                                 
	
	sh script_ejecutar_todo.sh
   
   2.1 El script ejecuta los programas con valores por defecto, para ejecutar imagenes con opciones diferentes, por favor lea el numeral 4.

4. Si desea correr pruebas independientes, es decir más allá de las que corre el script anterior, por favor ingrese al directorio 
GPU, Posix ó OMP, segun sea su interes, y ejecute el comando ./blur-efect <ruta_img> <radio_kernel> <numero_de_hilos>.
