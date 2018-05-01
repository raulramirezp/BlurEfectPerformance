## Requerimientos

   * Sistema operativo GNU/Linux, recomendamos Ubuntu o Debian
   * Para compilar este programa se requiere como minimo la version 2.8 de OpenCV, si no la tiene instalada la puede descargar desde su sitio oficial http://opencv.org/ e instalarlo como Opencv especifica.
   * Se requiere la versión de CUDA 8.0, o superior.

### Para compilar el programa ejecute el siguiente comando                                                                                                                                
	
	* sh buildAll.sh
	
### Para correr ejecute el comando                                                                 
	
	* sh script_ejecutar_todo.sh
   
   * El script ejecuta los programas con valores por defecto, para ejecutar imagenes con opciones diferentes, por favor lea el numeral 4.

 Si desea correr pruebas independientes, es decir más allá de las que corre el script anterior, por favor ingrese al directorio 
GPU, Posix ó OMP, segun sea su interes, y ejecute el comando ./blur-efect <ruta_img> <radio_kernel> <numero_de_hilos>.
