'From Squeak3.9 of 7 November 2006 [latest update: #7067] on 7 May 2010 at 12:33:06 pm'!
SmartSyntaxInterpreterPlugin subclass: #GeziraBindingsPlugin
	instanceVariableNames: 'nile mem uniformRed uniformGreen uniformBlue uniformAlpha transformA transformB transformC transformD transformE transformF clipL clipT clipR clipB'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'GeziraBindings-Plugin'!

!GeziraBindingsPlugin methodsFor: 'initialize-release' stamp: 'yo 5/7/2010 12:28'!
initialiseModule
self cCode: '
#define fprintf(a, ...)
'.

	self export: true.
	nile := self cCode: 'nile_new (1, mem, sizeof (mem))'.
	clipL := clipT := 0.
	clipR := clipB := 16r3FFFFFFF.
	^true! !

!GeziraBindingsPlugin methodsFor: 'initialize-release' stamp: 'bf 2/3/2010 15:57'!
shutdownModule
	self export: true.
	self cCode: 'nile_free(nile)'.
	^true! !


!GeziraBindingsPlugin methodsFor: 'primitives' stamp: 'yo 5/7/2010 11:49'!
primitiveClip: aFloatArray
	self primitive: 'primitiveClip' parameters: #(FloatArray).

	(interpreterProxy sizeOfSTArrayFromCPrimitive: aFloatArray) < 4
		ifTrue: [^self fail: 'clip rect must have 4 elements'].
	
	clipL := aFloatArray at: 0.
	clipT := aFloatArray at: 1.
	clipR := aFloatArray at: 2.
	clipB := aFloatArray at: 3.
	! !

!GeziraBindingsPlugin methodsFor: 'primitives' stamp: 'yo 5/7/2010 10:42'!
primitiveRenderPath: path Into: formOop
	| pathSize formBits formWidth formHeight formDepth pipeline |
	self primitive: 'primitiveRenderPathInto' parameters: #(FloatArray Oop).
	self var: #formBits type: 'usqInt*'.
	self var: #pipeline type: 'nile_Kernel_t*'.

	pathSize := interpreterProxy sizeOfSTArrayFromCPrimitive: path.

	(interpreterProxy slotSizeOf: formOop) < 4 ifTrue: [^self fail: 'invalid form'].
	formBits := interpreterProxy fetchArray: 0 ofObject: formOop.
	formWidth := interpreterProxy fetchInteger: 1 ofObject: formOop.
	formHeight := interpreterProxy fetchInteger: 2 ofObject: formOop.
	formDepth := interpreterProxy fetchInteger: 3 ofObject: formOop.
	interpreterProxy failed ifTrue: [^self fail: 'invalid form'].
	(formDepth ~= 32) ifTrue: [^self fail: 'form must have depth 32'].

	self cCode: '
		pipeline = nile_Pipeline (nile,
			gezira_TransformBeziers (nile, transformA, transformB, transformC, transformD, transformE, transformF),
#define min(x, y) (x) < (y) ? (x) : (y)
#define max(x, y) (x) > (y) ? (x) : (y)
			gezira_ClipBeziers (nile, max(clipL, 0), max(clipT, 0), min(clipR, formWidth), min(clipB, formHeight)),
#undef min
#undef max
			gezira_DecomposeBeziers (nile),
			gezira_Render (nile,
				gezira_UniformColor (nile, uniformAlpha, uniformRed, uniformGreen, uniformBlue),
				gezira_WriteImage_ARGB32 (nile, formBits, formWidth, formHeight, formWidth)),
			NULL);
		nile_feed (nile, pipeline, path, 6, pathSize, 1);
		nile_sync (nile);

' inSmalltalk: [formWidth. formHeight. formDepth. formBits. path. pathSize. pipeline := nil. pipeline]! !

!GeziraBindingsPlugin methodsFor: 'primitives' stamp: 'yo 5/7/2010 12:29'!
primitiveRenderPath: path Over: formOop
	| pathSize formBits formWidth formHeight formDepth pipeline |
	self primitive: 'primitiveRenderPathOver' parameters: #(FloatArray Oop).
	self var: #formBits type: 'usqInt*'.
	self var: #pipeline type: 'nile_Kernel_t*'.

	pathSize := interpreterProxy sizeOfSTArrayFromCPrimitive: path.

	(interpreterProxy slotSizeOf: formOop) < 4 ifTrue: [^self fail: 'invalid form'].
	formBits := interpreterProxy fetchArray: 0 ofObject: formOop.
	formWidth := interpreterProxy fetchInteger: 1 ofObject: formOop.
	formHeight := interpreterProxy fetchInteger: 2 ofObject: formOop.
	formDepth := interpreterProxy fetchInteger: 3 ofObject: formOop.
	interpreterProxy failed ifTrue: [^self fail: 'invalid form'].
	(formDepth ~= 32) ifTrue: [^self fail: 'form must have depth 32'].

	self cCode: '
#define min(x, y) (x) < (y) ? (x) : (y)
#define max(x, y) (x) > (y) ? (x) : (y)
		if (uniformAlpha == 1.0) {
			fprintf(stderr, "pipeline = nile_Pipeline (nile,\n");
			fprintf(stderr, "	gezira_TransformBeziers (nile, %g, %g, %g, %g, %g, %g),\n", transformA, transformB, transformC, transformD, transformE, transformF);
			fprintf(stderr, "	gezira_ClipBeziers (nile, %i, %i, %i, %i),\n", max(clipL, 0), max(clipT, 0), min(clipR, formWidth), min(clipB, formHeight));
			fprintf(stderr, "	gezira_DecomposeBeziers (nile),\n");
			fprintf(stderr, "	gezira_Render (nile,\n");
			fprintf(stderr, "		gezira_UniformColor (nile, %g, %g, %g, %g),\n", uniformAlpha, uniformRed, uniformGreen, uniformBlue);
			fprintf(stderr, "		gezira_WriteImage_ARGB32 (nile, %p, %i, %i, %i))\n", formBits, formWidth, formHeight, formWidth);
			fprintf(stderr, "	NULL);\n");
		} else {
			fprintf(stderr, "pipeline = nile_Pipeline (nile,\n");
			fprintf(stderr, "	gezira_TransformBeziers (nile, %g, %g, %g, %g, %g, %g),\n", transformA, transformB, transformC, transformD, transformE, transformF);
			fprintf(stderr, "	gezira_ClipBeziers (nile, %i, %i, %i, %i),\n", max(clipL, 0), max(clipT, 0), min(clipR, formWidth), min(clipB, formHeight));
			fprintf(stderr, "	gezira_DecomposeBeziers (nile),\n");
			fprintf(stderr, "	gezira_Render (nile,\n");
			fprintf(stderr, "		gezira_CompositeSamplers (nile,\n");
			fprintf(stderr, "			gezira_UniformColor (nile, %g, %g, %g, %g),\n", uniformAlpha, uniformRed, uniformGreen, uniformBlue);
			fprintf(stderr, "			gezira_ReadImage_ARGB32 (nile, %p, %i, %i, %i),\n", formBits, formWidth, formHeight, formWidth);
			fprintf(stderr, "			gezira_CompositeOver (nile)),\n");
			fprintf(stderr, "		gezira_WriteImage_ARGB32 (nile, %p, %i, %i, %i),\n", formBits, formWidth, formHeight, formWidth);
			fprintf(stderr, "	NULL);\n");
		}
			
		if (uniformAlpha == 1.0) {
			pipeline = nile_Pipeline (nile,
 				gezira_TransformBeziers (nile, transformA, transformB, transformC, transformD, transformE, transformF),
				gezira_ClipBeziers (nile, max(clipL, 0), max(clipT, 0), min(clipR, formWidth), min(clipB, formHeight)),
   				gezira_DecomposeBeziers (nile),
				gezira_Render (nile,
       			    gezira_UniformColor (nile, uniformAlpha, uniformRed, uniformGreen, uniformBlue),
           			gezira_WriteImage_ARGB32 (nile, formBits, formWidth, formHeight, formWidth)),
     			NULL);
		} else {
			pipeline = nile_Pipeline (nile,
				gezira_TransformBeziers (nile, transformA, transformB, transformC, transformD, transformE, transformF),
				gezira_ClipBeziers (nile, max(clipL, 0), max(clipT, 0), min(clipR, formWidth), min(clipB, formHeight)),
#undef min
#undef max
				gezira_DecomposeBeziers (nile),
				gezira_Render (nile,
					gezira_CompositeSamplers (nile,
						gezira_UniformColor (nile, uniformAlpha, uniformRed, uniformGreen, uniformBlue),
						gezira_ReadImage_ARGB32 (nile, formBits, formWidth, formHeight, formWidth),
						gezira_CompositeOver (nile)),
						gezira_WriteImage_ARGB32 (nile, formBits, formWidth, formHeight, formWidth)),
				NULL);
		}

		fprintf(stderr, "float[%i] path = {", pathSize);
		{
			int i;
			for (i=0; i<pathSize; i++)
				if (i==0) fprintf(stderr, "%g", path[i]);
				else fprintf(stderr, ", %g", path[i]);
		}
		fprintf(stderr, "};\n");
		fprintf(stderr, "nile_feed (nile, pipeline, path, 6, %i, %i);\n", pathSize, 1);
		nile_feed (nile, pipeline, path, 6, pathSize, 1);

		fprintf(stderr, "nile_sync (nile);\n");
		nile_sync (nile);

' inSmalltalk: [formWidth. formHeight. formDepth. formBits. path. pathSize. pipeline := nil. pipeline]! !

!GeziraBindingsPlugin methodsFor: 'primitives' stamp: 'bf 2/3/2010 16:52'!
primitiveTransform: aFloatArray
	self primitive: 'primitiveTransform' parameters: #(FloatArray).

	(interpreterProxy sizeOfSTArrayFromCPrimitive: aFloatArray) < 6
		ifTrue: [^self fail: 'matrix must have 6 elements'].
	
	transformA := aFloatArray at: 0.
	transformB := aFloatArray at: 3.
	transformC := aFloatArray at: 1.
	transformD := aFloatArray at: 4.
	transformE := aFloatArray at: 2.
	transformF := aFloatArray at: 5.
	! !

!GeziraBindingsPlugin methodsFor: 'primitives' stamp: 'bf 2/3/2010 16:51'!
primitiveUniformColor: aFloatArray
	self primitive: 'primitiveUniformColor' parameters: #(FloatArray).

	(interpreterProxy sizeOfSTArrayFromCPrimitive: aFloatArray) < 4
		ifTrue: [^self fail: 'color must have 4 elements'].

	uniformRed := aFloatArray at: 0.
	uniformGreen := aFloatArray at: 1.
	uniformBlue := aFloatArray at: 2.
	uniformAlpha := aFloatArray at: 3.
	! !


!GeziraBindingsPlugin methodsFor: 'misc' stamp: 'bf 1/28/2010 15:44'!
fail: aString
	self var: #aString type: 'char*'.
	self msg: aString.	
	interpreterProxy success: false.
	^nil! !

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

GeziraBindingsPlugin class
	instanceVariableNames: ''!

!GeziraBindingsPlugin class methodsFor: 'translation' stamp: 'yo 5/7/2010 11:49'!
declareCVarsIn: cg
	super declareCVarsIn: cg.

	cg addHeaderFile: '"gezira.h"'.
	cg addHeaderFile: '"gezira-image.h"'.

	cg var: #nile type: #'nile_t*'.
	cg var: #mem declareC: 'char mem[8000000]'.
	cg var: #uniformRed type: #'nile_Real_t'.
	cg var: #uniformRed type: #'nile_Real_t'.
	cg var: #uniformRed type: #'nile_Real_t'.
	cg var: #uniformGreen type: #'nile_Real_t'.
	cg var: #uniformBlue type: #'nile_Real_t'.
	cg var: #uniformAlpha type: #'nile_Real_t'.
	cg var: #transformA type: #'nile_Real_t'.
	cg var: #transformB type: #'nile_Real_t'.
	cg var: #transformC type: #'nile_Real_t'.
	cg var: #transformD type: #'nile_Real_t'.
	cg var: #transformE type: #'nile_Real_t'.
	cg var: #transformF type: #'nile_Real_t'.
	cg var: #clipL type: #'nile_Real_t'.
	cg var: #clipT type: #'nile_Real_t'.
	cg var: #clipR type: #'nile_Real_t'.
	cg var: #clipB type: #'nile_Real_t'.
! !

!GeziraBindingsPlugin class methodsFor: 'translation' stamp: 'bf 1/28/2010 14:14'!
moduleName
	^'GeziraBindings'! !
