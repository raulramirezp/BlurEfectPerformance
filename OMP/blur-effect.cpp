#include <omp.h>
#include <stdio.h>
#include <cmath>
#include <sstream>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>

using namespace std;
using namespace cv;

/*Variables globales*/
Mat src;
Mat dst;
double radio_kernel;

/* Funciones*/
void prom_punto(int i, 	uchar* dataout);

/*Función principal*/
int main(int n, char* argv[])
{
	int N_THREADS = 0;

	if( n < 4 ){
		printf ("blur <ruta img> <kernel> <thread>\n" );
		return 0;
	}

	/// Carga la imagen
	src = imread( argv[1], 1);
	if( !src.data ){
		printf("Error");
		return -1;
	}
	printf( "imagen %dx%d\n", src.rows , src.cols );
	/*Size of Image*/
	size_t size = src.rows*src.cols*sizeof( uchar);

	//Inicializa la imagen que tendra el efecto
	dst = src.clone();
	for(int y = 0; y < src.rows; y++)
		for(int x = 0; x < src.cols; x++)
			dst.at<uchar>(y,x) = 0.0;
	// carga el radio_kernel del Kernel
	stringstream ss;
	ss << argv[2] ;
	ss >> radio_kernel;

	//Numero de hilos
	sscanf(argv[3], "%i" , &N_THREADS);
	omp_set_num_threads(N_THREADS);
	printf( "Numero de hilos %i \n",  N_THREADS );
	#pragma omp parallel
	{
		int id = omp_get_thread_num();
		int n_threads = omp_get_num_threads();

		int nl = src.rows;                    // number of lines
		int nc = src.cols * src.channels(); // number of elements per line

		for (int i = id; i <src.rows*nc ; i += n_threads) {
			uchar* dataout = dst.ptr<uchar>(i/nc);
			prom_punto(i,dataout);
		}
	}

	namedWindow("final");
	imshow("final", dst);

	//namedWindow("initial");
	//imshow("initial", src);
	imwrite( "../blur-effect.jpg",dst );

	//waitKey(0);

	return 0;
}

void prom_punto(int p, uchar* dataout){
	float sum1 =0, sum2 = 0, sum3 = 0,sum_peso;
	sum_peso= 0;
	int x = p%(src.cols*src.channels());
	int y = p/(src.cols*src.channels());

	for (int j = -radio_kernel; j <= radio_kernel; j++) {
		//dirección de la fila j +y
		uchar* data = src.ptr<uchar>(y+j);
		for (int i= -radio_kernel; i <= radio_kernel; i++) {
			if (((x + i-3) >= 0 && (x + i-3) <  src.cols*src.channels() )&& ((y + j) >= 0 && (y + j) < src.rows)) {
				float peso = exp(-(i*i + j*j) / (float)(2 * radio_kernel*radio_kernel)) / (3.141592 * 2 * radio_kernel*radio_kernel);
				/* promedio de cada canal, x es la posición en la fila y, teniendo en cuenta que es un arreglo de src.cols*src.channel()
				, en este caso son 3 canales RGB, entonces para obtener la posición correcta de cada canal debemos sumar i*3,
				 donde i es es iterador que va recorriendo segun el radio del kernel y 3 indica la cantidad de canales*/
				sum1 += peso*data[x+i*3-3];
				sum2 += peso*data[x+i*3-2];
				sum3 += peso*data[x+i*3-1];
				sum_peso += peso;

			}
		}
	}

    if( x-3 >=0 )
    {
	dataout[x-3]= (uchar)floor(sum1/sum_peso);
	dataout[x-2]= (uchar)floor(sum2/sum_peso);
	dataout[x-1]= (uchar)floor(sum3/sum_peso);
    }
	return;
}
