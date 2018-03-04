#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <iostream>
#include <cmath>
#include <sstream>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>

__device__ int *iToxy(int, int);
__device__ int xyToi(int, int, int);
__device__ uchar3 prom_punto(uchar3*, int, int, int, int);
__global__ void cudaBlur(uchar3*, uchar3*, int, int, int, int);
inline int _ConvertSMVer2Cores(int, int);

int main(int n, char* argv[])
{
	int THREADS = 0;
	int BLOCKS = 0;
	int total_threads;
	int cuda_err = cudaSuccess;
	int img_size = 0;
	float radio = -1;
	cv::Mat src;

	std::cout << CV_LOAD_IMAGE_GRAYSCALE << std::endl;

	//	Prueva que los parametros esten completos
	if (n != 4) {
		printf("blur <ruta img> <kernel> <thread>\n");
		return 0;
	}
	//Determina las caracteristicas de la targeta
	cudaSetDevice(0);
	cudaDeviceProp deviceProp;
	cudaGetDeviceProperties(&deviceProp, 0);
	int max_threads = _ConvertSMVer2Cores(deviceProp.major, deviceProp.minor);
	std::cout << "cores disponibles por multiprocesador: " << max_threads << std::endl;

	//Calculando bloques y threads por bloque
	std::stringstream ss;
	ss << argv[3];
	ss >> total_threads;
	
	BLOCKS = (total_threads / (max_threads * 2)) + 1;
	THREADS = total_threads / BLOCKS;

	//	Determina el radio del kernel
	ss.clear();
	ss << argv[2];
	ss >> radio;
	if (radio < 1) {
		std::cerr << " Radio incorrecto para el Kernel, debe ser mayor a 1\n";
		return -1;
	}
	std::cout << "Kernel radio: " << (int)floor(radio) << std::endl;

	//	Carga la imagen en host
	src = cv::imread(argv[1], CV_LOAD_IMAGE_COLOR);
	if (!src.data) {
		std::cerr << "Error al leer la imagen\n";
		return -1;
	}
	std::cout << "Imagen: " << src.cols << "x" << src.rows << std::endl;

	//	Determina el tamaño del bloque de memoria para la imagen
	img_size = src.cols*src.rows * sizeof(uchar3);
	std::cout << "Imagen: " << ((double)img_size) / 1e6 << " Mb." << std::endl;

	//	Reservar la memoria en device para imagen original
	uchar3 *src_d;
	cuda_err = cudaMalloc(&src_d, img_size);
	if (cuda_err != cudaSuccess) {
		std::cerr << "Error al reservar memoria para imagen src en GPU\n";
		return -1;
	}
	std::cout << "Memoria de imagen src reservada en device\n";

	//	Reservar la memoria en device para imagen de respuesta
	uchar3 *ans_d;
	cuda_err = cudaMalloc(&ans_d, img_size);
	if (cuda_err != cudaSuccess) {
		std::cerr << "Error al reservar memoria para imagen ans en GPU\n";
		return -1;
	}
	std::cout << "Memoria de imagen ans reservada en device\n";

	//	Copiar imagen original al puntero src en device
	cuda_err = cudaMemcpy(src_d, src.data, img_size, cudaMemcpyHostToDevice);
	if (cuda_err != cudaSuccess) {
		std::cerr << "Error al copiar imagen src a GPU\n";
		return -1;
	}
	std::cout << "imagen original copiada en device\n";

	std::cout << "Ejecutando " << BLOCKS << " bloques de " << THREADS << " threads." << std::endl;
	//	llamar proceso de blur paralelo
	cudaBlur <<< BLOCKS, THREADS >>> (src_d, ans_d, src.cols, src.rows, THREADS*BLOCKS, (int)std::floor(radio));

	//	Copia la respuesta del apuntador ans_d a src, desde el device al host
	cuda_err = cudaMemcpy(src.data, ans_d, img_size, cudaMemcpyDeviceToHost);
	if (cuda_err != cudaSuccess) {
		std::cerr << "Error al copiar la respuesta de GPU al host\n";
		return -1;
	}
	std::cout << "Respuesta copiada al host\n";

	//	Liberar memoria en device
	cuda_err = cudaFree(src_d);
	if (cuda_err != cudaSuccess) {
		std::cerr << "Error al liberar memoria src en GPU\n";
		return -1;
	}
	cuda_err = cudaFree(ans_d);
	if (cuda_err != cudaSuccess) {
		std::cerr << "Error al liberar memoria ans en GPU\n";
		return -1;
	}
	std::cout << "Memoria liberada en device\n";

	//	namedWindow("final");
	//	imshow("final", dst);

	//	namedWindow("initial");
	//	imshow("initial", src);
	imwrite("../thread_blur.jpg", src);

	//	cv::waitKey(0);

	return 0;
}

/**
* Recorre los puntos del vector de datos de la imagen haciendo el blur a cada uno de ellos
*/
__global__ void cudaBlur(uchar3 *src, uchar3 *ans, int cols, int rows, int n_threads, int radio) {
	int id = blockIdx.x * blockDim.x + threadIdx.x;
	for (int i = id; i < cols*rows; i += n_threads) {
		*(ans + i) = prom_punto(src, i, rows, cols, radio);
	}
	return;
}

/**
* Convierte i a una cordenada de la forma (x,y).
* Retorna un apuntador con 2 pociciones reservadas.
* En la primera almacena el valor de x
* En la segunda almacena el valor de y
*/
__device__ int *iToxy(int i, int cols) {
	int *ans;
	ans = (int*)malloc(2 * sizeof(int));
	*ans = i%cols;
	*(ans + 1) = i / cols;
	return ans;
}

/**
* convierte una cordenada (x,y) a un valor i para array
* Retorna un entero con el valor de i
*/
__device__ int xyToi(int x, int y, int cols) {
	return cols*y + x;
}

/**
* Halla la suma promediada de los pixeles vecinos en base a un kernel
* src*			Un apuntador a el vector de datos de la imagen
* pos:			El indice del pixel, el indice en base a un array unidimencional
* rows, cols:	dimenciones de la imagen que se esta procesando
* radio:		El radio del kernel para los pixeles vecinos
* Retorna un entero con el valor de i
*/
__device__ uchar3 prom_punto(uchar3* src, int pos, int rows, int cols, int radio) {
	float  sum_peso;
	float3 sum = {0,0,0};

	sum_peso = 0;

	int *ptr_aux = iToxy(pos, cols);
	int x = *ptr_aux;
	int y = *(ptr_aux + 1);
	free(ptr_aux);

	for (int k = -radio; k <= radio; k++) {
		for (int j = -radio; j <= radio; j++) {
			if ((x + k) >= 0 && (x + k) < cols &&
				(y + j) >= 0 && (y + j) < rows) {
				float peso = exp(-(k*k + j*j) / (float)(2 * radio*radio)) / (3.141592 * 2 * radio*radio);
				sum.x += peso * (*(src + xyToi(x + k, y + j, cols))).x;
				sum.y += peso * (*(src + xyToi(x + k, y + j, cols))).y;
				sum.z += peso * (*(src + xyToi(x + k, y + j, cols))).z;
				sum_peso += peso;
			}
		}
	}
	
	uchar3 ans;

	ans.x = (uchar)std::floor(sum.x / sum_peso);
	ans.y = (uchar)std::floor(sum.y / sum_peso);
	ans.z = (uchar)std::floor(sum.z / sum_peso);

	return ans;
}

/**
 * Funcion de "cuda_helper.h" localizada en samples/common para determinar el numero de cores por multiprocesador del device
 */
inline int _ConvertSMVer2Cores(int major, int minor)
{
	// Defines for GPU Architecture types (using the SM version to determine the # of cores per SM
	typedef struct
	{
		int SM; // 0xMm (hexidecimal notation), M = SM Major version, and m = SM minor version
		int Cores;
	} sSMtoCores;

	sSMtoCores nGpuArchCoresPerSM[] =
	{
		{ 0x20, 32 }, // Fermi Generation (SM 2.0) GF100 class
		{ 0x21, 48 }, // Fermi Generation (SM 2.1) GF10x class
		{ 0x30, 192 }, // Kepler Generation (SM 3.0) GK10x class
		{ 0x32, 192 }, // Kepler Generation (SM 3.2) GK10x class
		{ 0x35, 192 }, // Kepler Generation (SM 3.5) GK11x class
		{ 0x37, 192 }, // Kepler Generation (SM 3.7) GK21x class
		{ 0x50, 128 }, // Maxwell Generation (SM 5.0) GM10x class
		{ 0x52, 128 }, // Maxwell Generation (SM 5.2) GM20x class
		{ 0x53, 128 }, // Maxwell Generation (SM 5.3) GM20x class
		{ 0x60, 64 }, // Pascal Generation (SM 6.0) GP100 class
		{ 0x61, 128 }, // Pascal Generation (SM 6.1) GP10x class
		{ 0x62, 128 }, // Pascal Generation (SM 6.2) GP10x class
		{ -1, -1 }
	};

	int index = 0;

	while (nGpuArchCoresPerSM[index].SM != -1)
	{
		if (nGpuArchCoresPerSM[index].SM == ((major << 4) + minor))
		{
			return nGpuArchCoresPerSM[index].Cores;
		}

		index++;
	}

	// If we don't find the values, we default use the previous one to run properly
	printf("MapSMtoCores for SM %d.%d is undefined.  Default to use %d Cores/SM\n", major, minor, nGpuArchCoresPerSM[index - 1].Cores);
	return nGpuArchCoresPerSM[index - 1].Cores;
}