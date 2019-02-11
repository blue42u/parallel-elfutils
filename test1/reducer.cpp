#include <iostream>
#include <cilk/reducer.h>
#include <cilk/cilk.h>
#include <cilk/cilk_api.h>

using namespace std;


unsigned int var = 5;

class PtrMonoid;

class MyReducerView{

    protected:
	friend class PtrMonoid;
	unsigned i;
	unsigned* ptr;
	bool set;

    public:

	//typedef unsigned int* value_type;
	MyReducerView():i(1000000),ptr(NULL),set(false){}

	void calc_first(unsigned int ii, unsigned int* p){
		
		if( (i > ii) && (ptr == NULL)){
			i =  ii;
			ptr = p;
			set = true;	
		}
	}

	/*
        void reduce(MyReducerView* right){

		cout<<"Reducing the View"<<endl;	
         	if( this->getFlag() == false && right->getFlag() == true){
         	      this->setPtr(right->getPtr());
                      this->setIteration(right->getIteration());
                      this->setFlag(true);

		}
	}
	*/

        unsigned int getIteration(){ return i; }
	unsigned int* getPtr(){ return ptr;}
        bool getFlag(){return set;}

        void setIteration(unsigned int ii){ i=ii; }
 	void setPtr(unsigned int* p){ ptr = p; }
        void setFlag(bool flag){ set = flag; }
 
        unsigned int* view_get_value() const {cout<<"Iteration: "<<i<<endl;cout<<"Global Variable Value: "<<*ptr<<endl; return ptr;}

};

struct PtrMonoid : public cilk::monoid_base<unsigned int*, MyReducerView>{


        static void reduce(MyReducerView* left, MyReducerView* right){
           
		cout<<"Reduction"<<endl;
		// ASSUMPTION: LHS will always be assigned to iteration which is < then RHS
		if(left->getFlag() == false && right->getFlag() == true){
			left->setPtr(right->getPtr());
			left->setIteration(right->getIteration());
			left->setFlag(true);
		}

        }      
            

	static void identity(MyReducerView* reducerView){
		
		cout<<"Identity"<<endl;
		
		reducerView->setPtr(NULL);
		reducerView->setIteration(1000000);
		reducerView->setFlag(false);
	
	}

};

//typedef cilk::monoid_with_view<MyReducerView> PtrMonoid;

unsigned int* foo(){return &var;}


void set_ptr(unsigned int i, unsigned int*& ptr){

	if( i > 1000 && !ptr){
		ptr = foo(); 
	}

}


int main(int argc, char** argv){

	__cilkrts_set_param("nworkers", "4");

	cilk::reducer<PtrMonoid> ptr_monoid;
	cilk_for(unsigned int i = 0;i < 1000000;i++){
	
		unsigned int* ptr_local = NULL;
		set_ptr(i,ptr_local);
		if(ptr_local){
			ptr_monoid->calc_first(i, ptr_local);
		}	

	}
	ptr_monoid.get_value();
	return 0;

}
