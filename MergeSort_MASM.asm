TITLE MergeSort_MASM     (MergeSort_MASM.asm)

; Author: Steve Owens
; Last Modified: 11/21/2019
; Description:  This program generates an array of random values between 100 and 999 based on user input for
;				the number of terms (request).  The program then populates an array of size "request" with
;				pseudorandom numbers, displays the unsorted list, sorts the list, calculates and displays the
;			    median of the array, and then displays the sorted list to the user.  This program uses the
;				recursive algorithm mergeSort for sort functinality implemented with the source material as a 
;				guide at the website GeekforGeeks.com https://www.geeksforgeeks.org/merge-sort/.
;
; Implementation notes:
;				This program is implemented using procedures.
;				All parameters are passed on the system stack

INCLUDE Irvine32.inc

; (constant definitions)
MIN			EQU			<15>						;constant, min number of user requested numbers
MAX			EQU			<200>						;constant, max number of user requested numbers
LO			EQU			<100>						;constant, min range for random integers
HI			EQU			<999>						;constant, max range for random integers


.data
; (variable definitions - strings)
progName		BYTE		"Programmed by Steve Owens", 0  ; 26 BYTEs
ec2				BYTE		"**EC #2: Implement sortiing functionality using a recursive MergeSort alogorithm.**", 0
progTitle		BYTE		"Sorting Random Integers", 0 ; 24 BYTEs
info1			BYTE		"This program generates random numbers in the range [100 .. 999],", 13, 10,
							"displays the original list, sorts the list, and calculates the", 13, 10,
							"median value.  Finally, it displays the list sorted in descending order.", 0
prompt1			BYTE		"How many numbers should be generated? [15 .. 200]: ", 0
unsorted_title	BYTE		"The unsorted random numbers: ", 0  ; 30 BYTEs
result2			BYTE		"The median is ", 0
sorted_title	BYTE		"The sorted list:", 0
median			BYTE		"The median is ", 0
error			BYTE		"Invalid input", 0
outro1			BYTE		"Thank you for using my program!", 0

; (variable definitions - integers or array data)
request			DWORD		?							; user defined actual size of array at runtime
num_array		DWORD		MAX DUP(?)					; allocates sufficient memory for user input of 200
	
.code
;-----------------------------------------------------------------------------------------------------------------
;introduction 
;description: display program name and introduces programmer.  displays EC header.
;receives: none
;returns: validated user input in eax register
;preconditions:  none
;registers changed: none, all restored to pre-call state
;-----------------------------------------------------------------------------------------------------------------
introduction PROC

			pushad
			mov		edx, OFFSET progTitle
			call	WriteString
			call	CrLf
			mov		edx, OFFSET progName
			call	WriteString
			call	CrLf
			mov		edx, OFFSET ec2
			call	WriteString
			call	CrLf
			mov		edx, OFFSET info1
			call	WriteString
			call	CrLf

			popad
			ret

introduction ENDP
;-----------------------------------------------------------------------------------------------------------------
;get data
;description: get data from user, validate data, and store data in.
;receives: address of request on system stack
;returns: user input value for number (request) of random numbers
;preconditions:  none
;registers changed: eax, ebx, edx
;-----------------------------------------------------------------------------------------------------------------
getData PROC

			push	ebp
			mov		ebp, esp
			mov		ebx, [ebp + 8]

W1:
			mov		edx, OFFSET prompt1
			call	WriteString
			call	ReadInt
			
			cmp		eax, MIN
			jl		E1
			cmp		eax, MAX
			jg		E1
			mov		[ebx], eax					;mov value in eax to request address
			pop		ebp
			ret		4							;clean up the stack

E1:
			mov		edx, OFFSET error
			call	WriteString
			call	CrLf
			jmp		W1

getData ENDP
;-----------------------------------------------------------------------------------------------------------------
;fill array
;description: generate pseudorandom numbers and populate the unsorted array
;receives:  request by value and address of array by reference (address)
;returns: validated user input in EAX register, stored in address [ebp + 12]
;preconditions:  Irvine Library Randomize called prior to this procedure call to seed RandomRange
;registers changed: eax, edx, edi
;-----------------------------------------------------------------------------------------------------------------
fillArray PROC

			push	ebp
			mov		ebp, esp
			mov		edi, [ebp + 12]				;move address of num_array into edi, edi points to array
			mov		ecx, [ebp + 8]				; initialize ecx to size of array

			mov		edx, HI
			sub		edx, LO

L1:			mov		eax, edx					; get absolute range					; 899
			inc		eax																	; 900
			call	RandomRange					; [0 .. 899]
			add		eax, LO						; shift result to between 100-999 
			mov		[edi], eax					; store eax in address pointed to by edi
			add		edi, 4						; move to next array element (DWORD)
			loop	L1

			pop		ebp
			ret		8

fillArray ENDP
;-----------------------------------------------------------------------------------------------------------------
;sort List array
;description: main sorting function that sets up local variables for the left and right index points and takes
;             the num_array passed to it by reference and passes it into the 1st of two procedures for MergeSort.
;			  Once partitiation and merge have completed all operations, sortList is returned to and then sorList
;			  returns to main.  Mergesort uses indirect and direct recursion between partition and merge.
;receives:  request by value and address of array by reference (address)
;returns: none
;preconditions:  none
;registers changed: eax
;-----------------------------------------------------------------------------------------------------------------
sortList PROC

			push	ebp
			mov		ebp, esp
			sub		esp, 4						; create local [esp - 4]  left index
			sub		esp, 8						; create local [esp - 8]  right index

			mov		DWORD PTR [ebp - 4], 0		; left index set to 0 first index of array
			mov		eax, [ebp + 8]				; move request from stack into eax
			sub		eax, 1						; right index set to request - 1
			mov		DWORD PTR [ebp - 8], eax	; move right index into [ebp -8]

			push	[ebp + 12]				    ;; push num_array address on stack (pass by reference)
			push	[ebp - 4]					; push the local for left index onto stack
			push	[ebp - 8]					; push the local for right index onto stack

			call	partition		

			mov		esp, ebp					; remove locals from stack
			
			pop		ebp
			ret		8							; clean up the stack
sortList ENDP
;-----------------------------------------------------------------------------------------------------------------
;partition
;description: the recursive workhorse of mergeSort.  Uses the two indexes to control the while loop, if the left
;			  index is not less than the right index, the base case if reached and the procedure immediately returns.
;			  Otherwise, the function calculates a middle index and splits the array in two halfs by generating an
;			  array denoted by indexes [left - mid] and another [(mid + 1) - right].  It then calls itself twice in
;			  the body to further split the left and right arrays until the array size is 0 (left >= right). The
;			  indexes it generates and passes do not have any effect on the original array, it is just setting up
;			  indexes for calling of the merge procedure.  Finally the stack unwinds and merge is called on each
;			  segment to sort the num_array in place.  Has a O(n log n) time complexity with O(n) space complexity.
;receives:  address of array by reference (address) and two indexes by value, left and right of the array.
;returns:  fully sorted indexes of subarrays of size 1 (original array indexed into "arrays" of size 1).
;preconditions:  none
;registers changed: eax, ebx, edx
;
;sources:  This program uses the recursive algorithm mergeSort for sort functinality implemented with the source 
;		   material as a guide at the website GeekforGeeks.com https://www.geeksforgeeks.org/merge-sort/.
;-----------------------------------------------------------------------------------------------------------------
partition PROC

			push	ebp
			mov		ebp, esp

			mov		ebx, [ebp + 12]				; move left index into ebx
			mov		ecx, [ebp + 8]				; move right index into ecx

			cmp		ebx, ecx					; if left < right  base case for recursive procedure partition
			jge		BASE						; return without partitioning
			sub		esp, 4						; create local [esp - 4]  MID for partition
			
			mov		eax, [ebp + 12]
			add		eax, [ebp + 8]				; add left and right index in eax
			cdq									; extened eax into edx
			mov		ebx, 2
			div		ebx	
			mov		[ebp - 4], eax				; move quotient of result into local for MID [ebp -4]

			push	[ebp + 16]					; push num_array address onto stack
			push	[ebp + 12]					; push left index onto stack
			push	[ebp - 4]					; push mid index as new right index onto stack
			call	partition

			mov		eax, [ebp - 4]				; move MID back into eax
			add		eax, 1						; add 1 to create new left index for recursive call

			push	[ebp + 16]					; push num_array address onto stack
			push	eax							; push MID + 1 onto stack
			push	[ebp + 8]					; push right index onto stack
			call	partition


			push	[ebp + 16]					; push num_array address onto stack
			push	[ebp + 12]					; push left index onto stack
			push	[ebp - 4 ]					; push mid value onto stack
			push	[ebp + 8]					; push right index onto stack
			call	merge
			
BASE:
			mov		esp, ebp					; remove locals from stack
			pop		ebp
			ret		12							; clean up the stack
partition ENDP
;-----------------------------------------------------------------------------------------------------------------
;merge
;description: the function to takes the partitioned index and sort the num_array in place.  It accomplishes this by
;			  creating two local arrays left and right based on the passed in parameters.  Its then populates those
;			  arrays by copying the values in the indexes of the original array.  Once created it then uses three
;			  while loops to manipulate the local arrays and re-write the values of the original array in memory.
;			  To accomplish this is performs a comparsion of the local array elements from left to right and the 
;			  index with the lower value is assigned to the memory location for the original array. It then increments
;			  the index for the original array pointers and repeats this process until either the left array or right
;			  array last element has been reached.  The next two while loops allow the other local array left or right
;			  with remaining elements to be added to the end of the original array.  The result is a completely sorted
;			  original array of the same size in the original memory location.  Has a O(n log n) time complexity with 
;             O(n) space complexity.  The creation of the subarrays is the reason for the increased space complexity.
;receives:  address of array by reference (address) and three indexes by value, left, middle and right of the array.
;returns: fully sorted array in the original memory location for num_array.
;preconditions:  array is partitioned into subarrays of size 1, completely sorted arrays.
;registers changed: eax, ebx, edi, esi, ecx, edx
;
;sources:  This program uses the recursive algorithm mergeSort for sort functinality implemented with the source 
;		   material as a guide at the website GeekforGeeks.com https://www.geeksforgeeks.org/merge-sort/.
;-----------------------------------------------------------------------------------------------------------------
merge PROC
			; OFFSET num_array  [ebp + 20]
			; left index value  [ebp + 16]
			; mid index value   [ebp + 12]
			; right index value [ebp + 8]			
			push	ebp
			mov		ebp, esp
			sub		esp, 4						; local for length of left temp array [ebp - 4]
			sub		esp, 4						; local for length of right temp array [ebp - 8]

			;left array size
			mov		eax, [ebp + 12]
			mov		ebx, [ebp + 16]
			sub		eax, ebx
			inc		eax							; add one to size of left array
			mov		[ebp - 4], eax				; store result as local value for left array size
			sub		esp, 800					; allocate memory for left array (worst case) [ebp - 808] 200 * DWORD

			;populate left array
			mov		ecx, [ebp - 4]				; move length of left array into ecx
			mov		eax, [ebp + 16]				; move left index value into ebx
			mov		ebx, 4						; byte size of DWORD
			mul		ebx							; result in eax is used to shift index of edi prior to loop based on left index.

			lea		esi, [ebp - 808]			; starting address for left array into esi
			mov		edi, [ebp + 20]				; move address of num array into edi
			add		edi, eax					; shift based on left index math above
L1:
			mov		edx, [edi]
			mov		[esi], edx					; move value in address pointed edi into address pointed to by esi
			add		esi, 4
			add		edi, 4
			loop	L1						

			;right array size
			mov		eax, [ebp + 8]				
			mov		ebx, [ebp + 12]
			sub		eax, ebx
			mov		[ebp - 8], eax				; store result as local value for right array size
			sub		esp, 800					; allocate memory for right array (worst case) [ebp - 1608] 200 * DWORD

			;populate right array
			mov		ecx, [ebp - 8]				; move length of right array into ecx
			mov		eax, [ebp + 12]				; move mid index value into eax
			add		eax, 1
			mov		ebx, 4
			mul		ebx							; result in eax is used to shift index of edi prior to loop based on middle index.

			lea		esi, [ebp - 1608]			; starting address for right array into esi
			mov		edi, [ebp + 20]				; move address of num array into edi
			add		edi, eax					; shift based on middle index math above
			sub		esp, 4						; create local variable to hold update pointer to num_array element [ebp - 1612]		
			
R1:
			mov		edx, [edi]
			mov		[esi], edx					; move value in address pointed edi into address pointed to by esi
			add		esi, 4
			add		edi, 4
			loop	R1

			; alter num_array in memory

			sub		esp, 4						; local variable for counter I [ebp - 1616]
			sub		esp, 4						; local variable for counter J [ebp - 1620]
			
			mov		eax, 0
			mov		[ebp - 1616], eax			; initialize counter I to 0
			mov		[ebp - 1620], eax			; initialize counter J to 0
			
			lea		esi, [ebp - 808]			; move address of left array into esi
			lea		ecx, [ebp - 1608]			; move address of right array into esi
			mov		edi, [ebp + 20]				; move address of num_array into edi
		
			mov		eax, [ebp + 16]
			mov		ebx, 4
			mul		ebx
			add		edi, eax					; shift starting position of edi based on left index passed as param	

beginWhile1:
			; while ( i < left array size && j < right array size)
			mov		eax, [ebp - 1616]			; counter I
			mov		ebx, [ebp - 4]				; length of left array
			cmp		eax, ebx
			jge		endWhile1					; end loop if counter I index is >= size of left array
			mov		eax, [ebp - 1620]			; counter J
			mov		ebx, [ebp - 8]				; length of right array
			cmp		eax, ebx
			jge		endWhile1					; end loop if counter J index is also >= size of right array
												; code can only be reached if both conditions are true

			mov		eax, [esi]					; value in left array pointed to by esi
			mov		ebx, [ecx]					; value in right array pointed to by ecx
			cmp		eax, ebx
			jg		Greater
			mov		[edi], eax					; move left value into address pointed to by edi
			add		esi, 4						; increment left index
			mov		eax, [ebp - 1616]			; increment counter I by 1 and store back in memory
			inc		eax
			mov		[ebp - 1616], eax
			jmp		LessThanOrEQ
Greater:
			mov		[edi], ebx					; move right value into address pointed to by edi
			add		ecx, 4						; increment right index
			mov		eax, [ebp - 1620]			; increment counter J by 1 and store back in memory
			inc		eax
			mov		[ebp - 1620], eax

LessThanOREQ:
			add		edi, 4						; increment edi by 1 DWORD
			jmp		beginWhile1
endWhile1:


beginWhile2:
			; while ( i < left array size)
			mov		eax, [ebp - 1616]			; counter I
			mov		ebx, [ebp - 4]				; length of left array
			cmp		eax, ebx
			jge		endWhile2					; end loop if counter I index is >= size of left array

			mov		eax, [esi]					; move value in left array pointed to by esi into eax
			mov		[edi], eax					; move value in eax into array pointed to by edi
			add		esi, 4						; increment left index
			mov		eax, [ebp - 1616]			; increment counter I by 1 and store back in memory
			inc		eax
			mov		[ebp - 1616], eax
			add		edi, 4						; increment edi by 1 DWORD
			jmp		beginWhile2
endWhile2:

beginWhile3:
			; while (j < right array size)
			mov		eax, [ebp - 1620]			; counter J
			mov		ebx, [ebp - 8]				; length of right array
			cmp		eax, ebx
			jge		endWhile3					; end loop if counter J index is >= size of left array

			mov		eax, [ecx]					; move value in right array pointed to by ecx into eax
			mov		[edi], eax					; move value in eax into array pointed to by edi
			add		ecx, 4						; increment right index
			mov		eax, [ebp - 1620]			; increment counter J by 1 and store back in memory
			inc		eax
			mov		[ebp - 1620], eax
			add		edi, 4						; increment edi by 1 DWORD
			jmp		beginWhile3
endWhile3:
			mov		esp, ebp					; remove locals from stack
			pop		ebp	
			ret		16							; clean up stack
merge ENDP
;-----------------------------------------------------------------------------------------------------------------
;display Median
;description: calculate median for an array of odd or even size and print the value to the console
;receives:  request by value, address of array by reference (address)
;returns: none
;preconditions:  none
;registers changed: eax, ebx, edx, esi
;-----------------------------------------------------------------------------------------------------------------
displayMedian PROC

			push	ebp
			mov		ebp, esp
			sub		esp, 4						; local for mid1 if even size array [ebp - 8]
			sub		esp, 4						; local for mid2 if even size array	[ebp - 12]

			mov		edi, [ebp + 12]				; move address of num_array from stack into edi
			mov		eax, [ebp + 8]				; move array size from stack into eax
			mov		ebx, 2
			cdq
			div		ebx
			cmp		edx, 0
			je		evenNumber
			jmp		oddNumber

evenNumber:
			sub		eax, 1						; shift value in eax for 0 based array
			mov		ebx, 4						; move size DWORD into ebx
			mul		ebx							; multiply eax (array size) by 4
			
			add		edi, eax
			mov		ebx, [edi]					; move the value edi points to into ebx
			mov		[ebp - 4], ebx				; move value in ebx into [ebp - 4] for mid1

			add		edi, 4						; subtract one DWORD from edi
			mov		ebx, [edi]					; move the value edi points to into ebx
			xor		eax, eax					; zero out eax

			mov		eax, [ebp - 4]
			add		eax, ebx
			cdq
			mov		ebx, 2
			div		ebx							; average of mid1 and mid2 is in eax
			jmp		displayMed
			
oddNumber:

			sub		eax, 1						; shift value in eax for 0 based array
			mov		ebx, 4						; move size DWORD into ebx
			mul		ebx							; multiply eax (array size) by 4
			
			add		edi, eax
			mov		eax, [edi]					; move the value edi points to into ebx
			
displayMed:
			call	CrLf
			mov		edx, OFFSET median
			call	WriteString
			call	WriteDec					; print value in eax to console
			mov		al, 46						; ascii value for period
			call	WriteChar
			call	CrLf
			call	CrLf

			mov		esp, ebp					; clear out local variables
			pop		ebp
			ret		8							; clean up the stack
displayMedian ENDP
;-----------------------------------------------------------------------------------------------------------------
;display List
;description: print formatted values of the num_array 
;receives:  request by value, address of array by reference (address), unsorted_title by reference (address)
;returns: none
;preconditions:  none
;registers changed: eax, ebx, edx, esi
;-----------------------------------------------------------------------------------------------------------------
displayList PROC

			push	ebp
			mov		ebp, esp
			sub		esp, 4						; create local [esp - 4]
			mov		DWORD PTR [ebp - 4], 10		; local for words per line

			mov		esi, [ebp + 16]				; esi points to num_array pointer (1st element)
			mov		ecx, [ebp + 12]				; sets outer loop counter to size of array (size_array)
			mov		edx, [ebp + 8]				; mov the offset of unsorted_title into edx
			mov		ebx, 0						; initialize ebx to zero for words per line
			call	WriteString
			call	CrLf
L1:			
			mov		eax, [esi]
			call	WriteDec
			mov		al, 9						; ascii character for tab
			call	WriteChar
			inc		ebx
			cmp		ebx, [ebp - 4]
			jb		NEXT
			call	CrLf
			xor		ebx, ebx					; reset ebx to 0
NEXT:
			add		esi, 4
			loop	L1

			call	CrLf
			mov		esp, ebp					; remove local from the stack
			pop		ebp
			ret		12							; clean up the stack

displayList	ENDP
;----------------------------------------------------------------------------------------------------------------
;goodbye
;description: end program, exit message to user
;receives: none
;returns: none
;preconditions: none
;registers changed: edx
;----------------------------------------------------------------------------------------------------------------
goodbye PROC

			mov		edx, OFFSET outro1
			call	WriteString
			call	CrLf
			ret

goodbye ENDP
;----------------------------------------------------------------------------------------------------------------
;main function
;description: calls program procedures in order required order for proper execution of program.
;receives: none
;returns: none
;preconditions: none
;registers changed: none
;----------------------------------------------------------------------------------------------------------------
main PROC	
		
			call	Randomize
			call	introduction

			push	OFFSET request							; pass request by reference
			call	getData

			push	OFFSET num_array						; pass num_array pointer by reference
			push	request									; pass request by value
			call	fillArray

			push	OFFSET num_array						; pass num_array pointer by reference
			push	request									; pass request by value
			push	OFFSET unsorted_title					; pass unsorted_title by reference					
			call	displayList


			push	OFFSET num_array						; pass num_array pointer by reference
			push	request									; pass request by value
			call	sortList								; mergeSort

			push	OFFSET num_array						; pass num_array pointer by reference
			push	request									; pass request by value
			call	displayMedian
			
			push	OFFSET num_array						; pass num_array pointer by reference
			push	request									; pass request by value
			push	OFFSET sorted_title						; pass unsorted_title by reference	
			call	displayList

			call	goodbye

			exit	; exit to operating system

main ENDP
END main