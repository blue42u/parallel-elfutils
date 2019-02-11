#include <cilk/cilk.h>
#include <iostream>
int x;

void f()
{
	x = 1;
}


void g()
{
	x = 2;
}

int main(int argc, char **argv)
{
	_Cilk_spawn f();
	_Cilk_spawn g();
	std::cout << "x = " << x << std::endl;
	return 0;
}
