#!bin/bash
clear
echo "ingresando al directorio Posix"
cd Posix
cmake .
make
echo "compilación version serial Posix ..."
echo
cd ../GPU
make 
echo "compilación version paralela GPU ..."
cd ../OMP
cmake .
make 
echo "compilación version OpenMP ..."
