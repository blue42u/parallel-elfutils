#include<iostream>
#include<omp.h>
#include<bits/stdc++.h>
using namespace std;

unsigned int var = 5;

class CustomReduction{

	private:
	   unsigned int i;
	   unsigned int* ptr;
	   bool flag;

	public:

           CustomReduction():i(INT_MAX), ptr(NULL), flag(false){}
	   CustomReduction(unsigned int ii, unsigned int* p): i(ii), ptr(p){ 
		if(ptr)
	  		flag = true;
		else
			flag = false;
	   }
	   CustomReduction(unsigned int ii, unsigned int* p, bool f):i(ii),ptr(p),flag(f){}
	   CustomReduction set(unsigned int ii, unsigned int* p, bool f){
		i = ii;
		ptr = p;
		flag = f;	
		return *this;
	   }

	   unsigned int  getIteration(){return i;}
	   unsigned int* getPtr(){return ptr;}
	   bool getFlag(){return flag;}

	   void setIteration(unsigned int ii){ i=ii;}
 	   void setPtr(unsigned int* p){ ptr = p; }
	   void setFlag(bool f){ flag = f; }


};

CustomReduction calc_first(CustomReduction reducedValue, CustomReduction newValue){

	if( (reducedValue.getIteration() > newValue.getIteration()) && newValue.getPtr()  ){
	
		return reducedValue.set(newValue.getIteration(), newValue.getPtr(), true);
	}
	
	return reducedValue;

}

unsigned int* foo(){ return &var; }

void set_ptr(unsigned int i, unsigned int*& ptr){

	if(!ptr && i > 5000)
         	ptr = foo();

}


int main(int argc, char** argv){

	#pragma omp declare reduction(customReduction : class CustomReduction : omp_out = calc_first(omp_out, omp_in))\
	initializer(omp_priv = CustomReduction())

	CustomReduction reductionValue = CustomReduction();
	
	#pragma omp parallel for reduction(customReduction : reductionValue)
       	for(unsigned int i = 0; i< 1000000; i++){

		unsigned int* ptrLocal = NULL;
		set_ptr(i, ptrLocal);
		CustomReduction newValue =  CustomReduction(i, ptrLocal);

		if(newValue.getFlag()){
			reductionValue = calc_first(reductionValue, newValue);
		}

	}

	cout<<"Iteration: "<<reductionValue.getIteration()<<endl;

	return 0;
}
