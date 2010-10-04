//
// CFTensor
//
// Šhnlich aufbauen wie CFTree http://developer.apple.com/documentation/CoreFoundation/Reference/CFTreeRef/index.html
//

struct __CMTensor
{
	// inherited values
	__CMTensor *dim;		// dim vector
	CFIndex rhorho;		// number of dimensions
	unsigned long size;	// number of elements
	CFType *data;		// malloc()ed data
};

typedef struct __CMTensor *CMTensorRef;	// this is a "Tensor" data structure, i.e. an n-dimensional matrix

typedef CFType (*CMTensorDyadicFunctionRef)(CFType left, CFType right);		// dyadic operation
typedef CFType (*CMTensorMonadicFunctionRef)(CFType left, CFType right);	// monadic operation

CFType CMTensorDyadicAdd(CFType left, CFType right);		// addition etc. - return left if right is NULL and unity value if both are NULL
CFType CMTensorDyadicSubtract(CFType left, CFType right);
CFType CMTensorDyadicMultiply(CFType left, CFType right);
CFType CMTensorDyadicDivide(CFType left, CFType right);
CFType CMTensorDyadicResidue(CFType left, CFType right);
CFType CMTensorDyadicCircular(CFType left, CFType right);	// trigonometric functions
CFType CMTensorDyadicMaximum(CFType left, CFType right);
CFType CMTensorDyadicMinimum(CFType left, CFType right);
CFType CMTensorDyadicExponentitation(CFType left, CFType right);
CFType CMTensorDyadicLogarithm(CFType left, CFType right);

CFType CMTensorMonadicNegate(CFType right);			// change sign etc.
CFType CMTensorMonadicSquareRoot(CFType right);
CFType CMTensorMonadicSignum(CFType right);
CFType CMTensorMonadicReciprocal(CFType right);
CFType CMTensorMonadicExponential(CFType right);
CFType CMTensorMonadicNaturalLogaritm(CFType right);
CFType CMTensorMonadicFloor(CFType right);
CFType CMTensorMonadicCeiling(CFType right);
CFType CMTensorMonadicAbsoluteValue(CFType right);

CFTypeID CMTensorGetTypeID();

CMTensorRef CMTensorCreate(CMTensorRef dimensions);	// create tensor with given dimension vector
CMTensorRef CMTensorFromScalar(CFTypeRef object);	// convert e.g. CFNumber into a scalar (0-dimensional) tensor
CMTensorRef CMTensorFromInt(long int value);		// convert e.g. CFNumber into a scalar (0-dimensional) tensor
CMTensorRef CMTensorFromVector(CFTypeRef object);	// convert CFArray of e.g. CFNumber into a vector (1-dimensional) tensor
CMTensorRef CMTensorFromIndexes(CFIndex first, ...);	// create numerical index vector (end by value 0); note: index origin is 1!
CMTensorRef CMIota(CFIndex n);						// create vector with elements [1..n]; returns empty vector if n=0

CFType CMScalar(CMTensor tensor);				// get value of scalar (if it is one - otherwise return NULL)

CMTensor CMDyadicOperation(CMTensorDyadicFunctionRef function, CMTensor left, CMTensor right);	// pairwise apply function to elements of both tensors (must have same dimension!)
CMTensor CMMonadicOperation(CMTensorMonadicFunctionRef function, CMTensor tensor);			// apply function to all elements
CMTensor CMReduce(CMTensorDyadicFunctionRef function, CMTensor tensor, CFIndex dimension);	// reduce (e.g. sum up, maximize) along the specified dimension
CMTensor CMInnerProduct(CMTensorDyadicFunctionRef reduce, CMTensorDyadicFunctionRef combine, CMTensor left, CMTensor right);	// inner product = reduced outer product
CMTensor CMOuterProduct(CMTensorDyadicFunctionRef combine, CMTensor left, CMTensor right);	// outer product

CMTensor CMRavel(CMTensor right);	// make vector of all elements in index sequence
CMTensor CMRho(CMTensor right);		// get dimension vector
CMTensor CMReversal(CMTensor right, CFIndex dimension);		// revert along given dimension
CMTensor CMTransposition(CMTensor right);					// interchange last coordinates
CMTensor CMGradeup(CMTensor right);					// sort index
CMTensor CMGradedown(CMTensor right);				// sort index
CMTensor CMReshape(CMTensor dimensions, CMTensor right);	// reshape (delete elements or replicate)
CMTensor CMCatenate(CMTensor left, CMTensor right);			// catenate vectors
CMTensor CMRotation(CMTensor left, CMTensor right, CFIndex dimension);			// rotate right tensor along dimension; number of elements is given by left
CMTensor CMIndex(CMTensor left, CMTensor right);
CMTensor CMCompression(CMTensor left, CMTensor right, CFIndex dimension);		// take only elements where left is 1
CMTensor CMExpansion(CMTensor left, CMTensor right, CFIndex dimension);			// expand

// EOF