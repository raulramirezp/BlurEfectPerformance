all:	
	nvcc  -Wno-deprecated-gpu-targets  `pkg-config --cflags --libs opencv`   -I /usr/local/cuda-8.0/include/ -L /usr/local/cuda/lib64/ -lcuda -lcudart -lopencv_core -lopencv_highgui -lopencv_imgproc $(wildcard *.cu) -o blur-effect
