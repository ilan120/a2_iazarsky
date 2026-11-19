No Makefile compile with:

g++ -O2 -pthread -o out_a src/partA.cpp
g++ -O2 -fopenmp -o out_b src/partB.cpp

// depending on partA or partB
Usage: ./out_(a/b) <M> <K> <N> <pr> <pc> <b>

All required runs are available in scripts directory
