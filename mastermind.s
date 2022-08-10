	#Program that represents the Mastermind game. The CPU generates a random number that has digitCt
	#digits (where the digits are unique and the first digit is never 0), and the user attempts to 
	#guess the CPU's number by inputting guesses into the program. The user receives a response. 
	#("Fermi" means a digit in the user's guess appears in the same place in the target number, 
	#"Pico" means a digit in the user's guess appears in the target number, but it's in a different
	#position from what the user entered, and "Bagel" means no digits in the user's guess appear
	#in the target number.) The user can enter repeated guesses, and they can enter all zeroes to 
	#indicate they want to end the game. Also, this program be adjusted to generate target numbers and to accept
	#guesses of any length between 1 and 10 by changing the value of digitCt.
        #Written by Jake Heyser
            
        .data
        .align	2
userPrompt:	.asciiz "Enter your guess: "
quitPrompt:	.asciiz "Thank you for playing. The target number was: "
guessPrompt:	.asciiz "The number of guesses you have inputted is: "
winPrompt:	.asciiz "Congratulations! You have correctly guessed the target number!"
answer:		.word	0, 0, 0, 0, 0, 0, 0, 0, 0, 0
userGuess:	.word	0, 0, 0, 0, 0, 0, 0, 0, 0, 0
guessCount:	.word	0
digitCt:		.word	4
fermiPrmpt:	.asciiz	"Fermi"
picoPrmpt:	.asciiz "Pico"
bagelPrmpt:	.asciiz	"Bagel"
digitCtPrmpt:	.asciiz	"You did not enter the right amount of digits. Try again."
firstDgErPrmpt:	.asciiz "You did not enter a valid guess; you either did not enter enough digits or the first number you entered was 0. Try again."
repDgErPrmpt:	.asciiz "You did not enter a valid guess; your guess had repeating digits. Try again."

#---------------------------------------------------

        .text
        .globl  main

main:	#First, we need to tell the user to input a guess.
	li	$v0, 51		#setting up for the syscall
	la	$a0, userPrompt	#getting the user's guess and loading it into a0
	syscall

	move	$s0, $a0		#s0: the user's guess
	lw	$a0, digitCt	#a0: the number of digits we want our target number to be
	move	$s1, $a0		#s1: digitCt (so we have it in a s-register)
	la	$a1, answer	#a1: the address of the start of answer
	move	$s2, $a1		#s2: the address of the start of answer (so we have it in a s-register)
	
	#call the function to generate the (random) target number and store it in memory
	jal	genTarNum
	move	$s6, $v0		#s6: the target number
		
	#setting up for the call to check if the first digit in answer is 0
	move	$a0, $s2		#a0: the address of the start of answer
	jal	checkForZero	#making the call to the function that checks to see if the first digit in answer is 0
	
loop1:	bne	$v0, 1, next	#while (the first number in answer == 0)
start:	move	$a0, $s1		#a0: digitCt
	move	$a1, $s2		#a1: the address of the start of answer
	jal	genTarNum	#call the function to generate a new target number
	move	$s6, $v0		#s6: the target number
	move	$a0, $s2		#a0: the address of the start of answer
	jal	checkForZero	#call the function to see if the first digit in the target number is 0
	j	loop1		#return back to the top of the loop to see if we need to continue generating a new target number
	
	#At this point, we know our target number does not begin with a 0 and has the right amount of digits.
	#We now need to check to see if every digit is unique.
next:	move	$a0, $s2		#a0: the address of answer
	move	$a1, $s1		#a1: the number of elements in answer (n)
	jal	areDigitsUnique	#call the function to see if the digits in the target number are unique
	bne	$v0, 1, next1	#if (the digits are not unique in answer)
	j	start		#need to repeat the process of generating a new target and error-checking the new number	
	
	#At this point, we have a valid target number stored in s6 and in memory in answer.
	
	#setting up the call to the function that checks to see if the user's guess contains the right amount of digits
next1:	move	$a0, $s1		#a0: the number of digits in the target number
	move	$a1, $s0		#a1: the user's guess
	jal	checkDigitCt	#calling the function

	move	$t7, $v0		#t7: the value returned by the function
	
	#setting up the call to the function that breaks up the user's guess into digits and stores
	#them in memory (in userGuess)
next2:	move	$a0, $s0		#a0: the user's guess
	la	$a1, userGuess	#a1: the address of the list we want to store the user's digits into
	move	$a2, $s1		#a2: the number of digits in the target number
	jal	breakUpGuess	#call the function to break up the user's guess into digits and stores them in memory
	
	#At this point, the user's guess is stored backward in userGuess.
	
	#We will now set up the call to the function that reverses the order of the user's digits in memory
	#so that they are in stored in the correct order in userGuess. 
	la	$a0, userGuess	#a0: the address of the list we are storing the user's digits into
	move	$a1, $s1		#a1: digitCt
	jal	listReversal	#call the function to reverse the digits in UserGuess
	
	#setting up the call to check to see if the user wants to quit
	la	$a0, userGuess	#a0: the address of the list we are storing the user's digits into
	move	$a1, $s1		#a1: digitCt
	jal	checkQuit	#call the function to see if the user wants to quit
	bne	$v0, 1, next3	#if (the user entered all zeroes, meaning they want to quit)
	j	quit		#jump to the part of the program that deal with quitting
	
	#At this point, the digits of the user's guess are stored in the right order in userGuess. We know
	#that they entered the right amount of digits. Now, we'll set up the call to the function that
	#checks to see if the first digit the user inputted was 0.
next3:	la	$a0, userGuess	#a0: the address of the list we are storing the user's digits into
	jal	checkForZero	#call the function to see if the first digit in the user's guess is 0
	
	#checking to see if the first digit the user inputted was 0
	bne	$v0, 1, next4	#if (the first number of the user's input is 0)
	j	error2		#jump to the part of the program that displays a 0-as-first-digit error message to the user

next4:	bne	$t7, 0, next5	#if (t7 == 0)(meaning the user doesn't want to quit and they didn't input 0 as 
	#the first digit in their guess, yet they inputted a value < smallest legal input)
	j	error1		#jump to the part of the program that displays the error message about inputting
	#the wrong number of digits to the user
	
	#We now know the user inputted the right amount of digits and the first digit in their guess was not
	#0. We also know they do not want to quit.
	
next5:	la	$a0, userGuess	#a0: the address of the list we are storing the user's digits into
	move	$a1, $s1		#a1: the number of digits in the user's guess
	jal	areDigitsUnique	#call the function to see if the digits in the user's guess are unique
	bne	$v0, 1, next6	#if (the digits are not unique in the user's guess)
	j	error3		#jump to the part of the program that displays a digits-aren't-unique error message to the user
	
	#At this point, we know the user's guess is valid (and is stored in userGuess)
next6:	la	$a0, userGuess	#a0: address of the list we are storing the user's digits into
	la	$a1, answer	#a1: address of the target number
	move	$a2, $s1		#a2: the number of digits the target number is
	jal	getFermiCt	#call the function to get the number of "Fermi" responses the user should receive
	move	$s3, $v0		#s3: the number of "Fermi" responses the user should receive
	jal	getPicoCt	#call the function to get the number of "Pico" responses the user should receive
	move	$s4, $v0		#s4: the number of "Pico" responses the user should receive
	add	$s5, $s3, $s4	#s5: the sum of the number of "Pico" and "Fermi" responses the user should receive
	bne	$s5, 0, chkFerm	#if (the number of "Pico" and "Fermi" responses the user should receive == 0)
	
	#want to return "Bagel" to the user
	li	$v0, 55		#setting up for the syscall
	li	$a1, 1		#a1: 1 (for the syscall)
	la	$a0, bagelPrmpt	#a0: the address of the "Bagels" prompt we want to return to the user
	syscall			#return "Bagels" to the user
	
	#need to update the guess count of the user
	la	$t6, guessCount	#t6: the address of guessCount in memory
	lw	$t7, 0($t6)	#t7: guessCount
	addi	$t7, $t7, 1	#guessCount++
	sw	$t7, 0($t6)	#storing the updated value of guessCount in memory
	
	#Now, we need to tell the user to input a new guess, so we can then repeat the process
	#of checking their guesses against the target number
	li	$v0, 51		#setting up for the syscall
	la	$a0, userPrompt	#a0: the prompt to signal the user to input a new guess
	syscall			#returning the guess prompt to the user
	move	$s0, $a0		#s0: the user's new guess (so we can use it for the error-checking)
	j	next1		#return back to performing error-checking on the user's new guess

chkFerm:	bne	$s3, $s1, print	#if (the number of "Fermi" responses == the number of digits in target number)

	#want to return "congratulations" prompt; the user guessed the target number
	li	$v0, 55		#setting up for the syscall
	li	$a1, 1		#a1: 1 (for the syscall)
	la	$a0, winPrompt	#a0: the address of the prompt congratulating the user
	syscall			#returning the "congratulations" message to the user
	
	#need to update the guess count of the user
	la	$t6, guessCount	#t6: the address of guessCount in memory
	lw	$t7, 0($t6)	#t7: guessCount
	addi	$t7, $t7, 1	#guessCount++
	sw	$t7, 0($t6)	#storing the updated value of guessCount in memory
	
	#want to return the number of guesses the user made
	la	$t6, guessCount	#t6: the address of guessCount in memory
	lw	$t7, 0($t6)	#t7: guessCount
	move	$a1, $t7		#a1: guessCount
	li	$v0, 56		#setting up for the syscall
	la	$a0, guessPrompt	#return the guess prompt to the user
	syscall			#returning the number of guesses to the user
	
	#termination of program
	li	$v0, 10
	syscall
	
	#print the "Fermi" responses to the user
print:	li	$t0, 0		#t0: index = 0
fermiLp:	bge	$t0, $s3, update	#while (index < (the number of "Fermi" responses the user should receive))
	
	li	$v0, 55		#setting up for the syscall
	li	$a1, 1		#a1: 1 (for the syscall)
	la	$a0, fermiPrmpt	#a0: the address of the "Fermi" prompt we want to return to the user
	syscall			#return "Fermi" to the user
	addi	$t0, $t0, 1	#index++
	j	fermiLp		#return back to the top of the loop so we can print more "Fermi" responses (if needbe)
	
	#need to update the guess count of the user
update:	la	$t6, guessCount	#t6: the address of guessCount in memory
	lw	$t7, 0($t6)	#t7: guessCount
	addi	$t7, $t7, 1	#guessCount++
	sw	$t7, 0($t6)	#storing the updated value of guessCount in memory
	
	#print the "Pico" responses to the user
	li	$t0, 0		#t0: index = 0
picLp:	bge	$t0, $s4, procd	#while (index < (the number of "Pico" responses the user should receive))
	li	$v0, 55		#setting up for the syscall
	li	$a1, 1		#a1: 1 (for the syscall)
	la	$a0, picoPrmpt	#a0: the address of the "Pico" prompt we want to return to the user
	syscall			#return "Pico" to the user
	addi	$t0, $t0, 1	#index++
	j	picLp		#return back to the top of the loop so we can print more "Pico" responses (if need be)
	
procd:	#Now, we need to tell the user to input a new guess, so we can then repeat the process
	#of checking their guesses against the target number
	li	$v0, 51		#setting up for the syscall
	la	$a0, userPrompt	#a0: the prompt to singal the user to input a new guess
	syscall			#returning the prompt to the user to signal them to enter a new guess
	move	$s0, $a0		#s0: the user's new guess (so we can use it for the error-checking)
	j	next1		#return back to performing error-checking on the user's new guess

error1:	#need to display the error message "digitCtPrmpt" to the user
	li	$v0, 55		#setting up for the syscall
	li	$a1, 1		#a1: 1 (for the syscall)
	la	$a0, digitCtPrmpt	#a0: the address of the error message we want to return to the user
	syscall			#returning the error message about entering the right amount of digits to the user
	
	#Now, we need to tell the user to input a new guess, so we can then repeat the process
	#of checking their guesses against the target number
	li	$v0, 51		#setting up for the syscall
	la	$a0, userPrompt	#a0: the prompt to singal the user to input a new guess
	syscall			#returning the prompt to the user to singal them to enter a new guess
	move	$s0, $a0		#s0: the user's new guess (so we can use it for the error-checking)
	j	next1		#return back to performing error-checking on the user's new guess
	
quit:	#need to display the quit prompt to the user, display the target number and return their number of valid guesses
	#displaying the quit prompt to the user
	move	$a1, $s6		#a1: the target number
	li	$v0, 56		#setting up for the syscall
	la	$a0, quitPrompt	#a0: the address of the quit prompt we want to return to the user
	syscall			#returning the quit prompt to the user
	
	#want to return the number of guesses the user made
	la	$t6, guessCount	#t6: the address of guessCount in memory
	lw	$t7, 0($t6)	#t7: guessCount
	move	$a1, $t7		#a1: guessCount
	li	$v0, 56		#setting up for the syscall
	la	$a0, guessPrompt	#a0: the address of the guess prompt for the user
	syscall			#returning the number of guesses to the user
	
	#termination of program
	li	$v0, 10
	syscall
	
error2:	#need to display the error message for having zero as the first digit in the user's guess
	li	$v0, 55		#setting up for the syscall
	li	$a1, 1		#a1: 1 (for the syscall)
	la	$a0, firstDgErPrmpt	#a0: the address of the error message we want to return to the user
	syscall			#returning the error message about having 0 as the first digit in their guess to the user
	
	#Now, we need to tell the user to input a new guess, so we can then repeat the process
	#of checking their guesses against the target number
	li	$v0, 51		#setting up for the syscall
	la	$a0, userPrompt	#a0: the address of the prompt to singal the user to input a new guess
	syscall			#returning the prompt to the user to signal them to enter a new guess
	move	$s0, $a0		#s0: the user's new guess (so we can use it for the error-checking)
	j	next1		#return back to performing error-checking on the user's new guess
	
error3:	#need to display the error message for having repeating digits in the user's guess
	li	$v0, 55		#setting up for the syscall
	li	$a1, 1		#a1: 1 (for the syscall)
	la	$a0, repDgErPrmpt	#a0: the address of the error message we want to return to the user
	syscall			#returning the error message about having repeating digits in their guess to the user
	
	#Now, we need to tell the user to input a new guess, so we can then repeat the process
	#of checking their guesses against the target number
	li	$v0, 51		#setting up for the syscall
	la	$a0, userPrompt	#a0: the address of the prompt to singal the user to input a new guess
	syscall			#returning the prompt to the user to signal them to entere a new guess
	move	$s0, $a0		#s0: the user's new guess (so we can use it for the error-checking)
	j	next1		#return back to performing error-checking on the user's new guess
	
	
#----------------------------genTarNum-------------------------------
		#function that generates a random number (our target number) that has digitCt digits,
		#stores these digits in answer and returns the value in decimal of the target number that
		#was generated

		#a0: the number of digits we want our target number to be
		#a1: the address of the start of answer

genTarNum:							
#----------------------- function preamble  ---------------------------------
        addi	$sp, $sp, -36	#allocate stack space for 9 values	
        sw	$ra, 0($sp)	#store off the return address		
        sw	$s0, 4($sp)	#store off s0		
        sw	$s1, 8($sp)	#store off s1
        sw	$s2, 12($sp)	#store off s2
        sw	$s3, 16($sp)	#store off s3
        sw	$s4, 20($sp)	#store off s4
        sw	$s5, 24($sp)	#store off s5
        sw	$s6, 28($sp)	#store off s6
        sw	$s7, 32($sp)	#store off s7


#-------------------------- function body -------------------------
	move	$s0, $a0		#s0: the number of digits we want our target number to be
	move	$t0, $a1		#t0: the address of the start of answer
	li	$s1, 0		#s1: our index for forming the target number
	li	$s2, 0		#s2: our running total for the targetNumber
	addi	$t1, $s0, -1	#t1: digitCt - 1 (our starting exponent of 10 for calculating the target number)
	#generating digitCt random numbers from [0,9] so we can formulate our target number
loop:	bge	$s1, $s0, complt	#while (index < digitCt)
	li	$v0, 42		#loading 42 into v0 for the syscall
	li	$a1, 9		#a1: the upper bound of range for a digit in the target number
	syscall			#generating a new random number between 0 and 9 (inclusive)
	
	#a0 now contains the newly generated random digit
	#want to update our running total to include the newest digit 
	move	$t3, $t1		#t3: our index for the number of times we need to multiply by 10 that we can increment
	li	$t2, 1		#t2: our base number we will use for multiplying by 10 to find the target number
	li	$s3, 1		#s3: a dummy variable to help us calculate the target number
topLp:	ble	$t3, 0, goHome	#while (indexOf10 > 0)
	mul	$s4, $t2, 10	#multiplying by 10 to find the value of 10^(digitCt - (index + 1))
	mul	$s3, $s3, $s4	#updating our value for the current digit in decimal 
	addi	$t3, $t3, -1	#indexOf10--
	j	topLp		#return back to the top of the loop to keep updating the correct power of 10 for the new digit 
	
	#want to update the running total for targetNumber
goHome:	mul	$t4, $a0, $s3	#t4: the value in decimal of the newest digit in decimal in its position in the target number
	add	$s2, $s2, $t4	#updating the running total for target number
	addi	$t1, $t1, -1	#updating the exponent of 10 for the next digit
	
	sw	$a0, 0($t0)	#storing the new digit in answer at index = digitCt
	addi	$t0, $t0, 4	#updating the offset for answer
	addi	$s1, $s1, 1	#index++
	j	loop		#return back to the start of the loop for adding digits to answer
	
complt:	move	$v0, $s2		#want to return the target number
	
#----------------------- function epilogue  -----------------------	
	lw	$ra, 0($sp)	#restore the return address	
	lw	$s0, 4($sp)	#restore the value of s0	
	lw	$s1, 8($sp)	#restore the value of s1
	lw	$s2, 12($sp)	#restore the value of s2
	lw	$s3, 16($sp)	#restore the value of s3
	lw	$s4, 20($sp)	#restore the value of s4
	lw	$s5, 24($sp)	#restore the value of s5
	lw	$s6, 28($sp)	#restore the value of s6
	lw	$s7, 32($sp)	#restore the value of s7
	addi	$sp, $sp, 36	#update the stack pointer
	jr	$ra		#return to the calling function
	

#----------------------------checkForZero-------------------------------
		#function that checks to see if the first digit in a list is 0; if not, returns 0,
		#and if so, returns 1

		#a0: the address of the start of the list in memory we want to check
	
checkForZero:						
#----------------------- function preamble  ---------------------------------
       addi	$sp, $sp, -36	#allocate stack space for 9 values	
        sw	$ra, 0($sp)	#store off the return address		
        sw	$s0, 4($sp)	#store off s0		
        sw	$s1, 8($sp)	#store off s1
        sw	$s2, 12($sp)	#store off s2
        sw	$s3, 16($sp)	#store off s3
        sw	$s4, 20($sp)	#store off s4
        sw	$s5, 24($sp)	#store off s5
        sw	$s6, 28($sp)	#store off s6
        sw	$s7, 32($sp)	#store off s7


#-------------------------- function body -------------------------
	move	$t0, $a0		#t0: the address of the start of our list
	lw	$s0, 0($t0)	#s0: the first number in the list
	bne	$s0, 0, done	#if (s0 == 0)
	li	$v0, 1		#want to return 1 to the user
	j	finish		#we are ready to end the function
done:	li	$v0, 0		#want to return 0 to the user
	
#----------------------- function epilogue  -----------------------	
finish:	lw	$ra, 0($sp)	#restore the return address	
	lw	$s0, 4($sp)	#restore the value of s0	
	lw	$s1, 8($sp)	#restore the value of s1
	lw	$s2, 12($sp)	#restore the value of s2
	lw	$s3, 16($sp)	#restore the value of s3
	lw	$s4, 20($sp)	#restore the value of s4
	lw	$s5, 24($sp)	#restore the value of s5
	lw	$s6, 28($sp)	#restore the value of s6
	lw	$s7, 32($sp)	#restore the value of s7
	addi	$sp, $sp, 36	#update the stack pointer
	jr	$ra		#return to the calling function
	

#---------------------------areDigitsUnique-------------------------------
		#function that checks to see if all the digits in a list are unique; if so, returns 0,
		#and if not, returns 1
		
		#a0: the address of the start of the list in memory we want to check
		#a1: the number of elements in the list (n)	

areDigitsUnique:								
#----------------------- function preamble  ---------------------------------
        addi	$sp, $sp, -36	#allocate stack space for 9 values	
        sw	$ra, 0($sp)	#store off the return address		
        sw	$s0, 4($sp)	#store off s0		
        sw	$s1, 8($sp)	#store off s1
        sw	$s2, 12($sp)	#store off s2
        sw	$s3, 16($sp)	#store off s3
        sw	$s4, 20($sp)	#store off s4
        sw	$s5, 24($sp)	#store off s5
        sw	$s6, 28($sp)	#store off s6
        sw	$s7, 32($sp)	#store off s7
        

#-------------------------- function body -------------------------
	move	$t0, $a0		#t0: the address of the start of our list that we can increment
	move	$t2, $t0		#t2: the address of the start of our list that we can reference throughout the function
	move	$s0, $a1		#s0: the number of elements in the list (n)
	addi	$s1, $s0, -1	#s1: n - 1
	li	$s2, 0		#s2: index = 0
loop2:	bge	$s2, $s1, done1	#while (index < n -1)
	addi	$s3, $s2, 1	#s3: j = index + 1
	lw	$s4, 0($t0)	#s4: list[index]
loop3:	bge	$s3, $s0, cont	#while (j < n)
	sll	$t1, $s3, 2	#t1: the offset for calculating list[j]
	add	$t1, $t2, $t1	#t1: the address of list[j]
	lw	$s5, 0($t1)	#s5: list[j]
	bne	$s4, $s5, nxt1	#if (list[i] == list[j])
	li	$v0, 1		#want to return 1 
	j	finish1		#we are done
nxt1:	addi	$s3, $s3, 1	#j++
	j	loop3		#return to the top of the inner loop
cont:	addi	$s2, $s2, 1	#index++
	addi	$t0, $t0, 4	#updating the address of list[i]	
	j	loop2		#return to the top of the outer loop
done1:	li	$v0, 0		#want to return 0; all digits are unique
	
#----------------------- function epilogue  -----------------------	
finish1:	lw	$ra, 0($sp)	#restore the return address	
	lw	$s0, 4($sp)	#restore the value of s0	
	lw	$s1, 8($sp)	#restore the value of s1
	lw	$s2, 12($sp)	#restore the value of s2
	lw	$s3, 16($sp)	#restore the value of s3
	lw	$s4, 20($sp)	#restore the value of s4
	lw	$s5, 24($sp)	#restore the value of s5
	lw	$s6, 28($sp)	#restore the value of s6
	lw	$s7, 32($sp)	#restore the value of s7
	addi	$sp, $sp, 36	#update the stack pointer
	jr	$ra		#return to the calling function


#-----------------------------------------------checkQuit-------------------------------------------------
		#function that checks to see whether the user wants to quit (and entered all zeroes); if so,
		#returns 1, and if not, returns 0
		
		#a0: the address of the start of the list that contains the digits of the user's guess
		#a1: the number of digits in the user's guess
				
checkQuit:						
#----------------------- function preamble  ---------------------------------
        addi	$sp, $sp, -36	#allocate stack space for 9 values	
        sw	$ra, 0($sp)	#store off the return address		
        sw	$s0, 4($sp)	#store off s0		
        sw	$s1, 8($sp)	#store off s1
        sw	$s2, 12($sp)	#store off s2
        sw	$s3, 16($sp)	#store off s3
        sw	$s4, 20($sp)	#store off s4
        sw	$s5, 24($sp)	#store off s5
        sw	$s6, 28($sp)	#store off s6
        sw	$s7, 32($sp)	#store off s7


#-------------------------- function body ------------------------- 
	move	$t0, $a0		#t0: the address of the start of userGuess
	move	$s0, $a1		#s0: the number of digits in the user's guess
	li	$v0, 0		#v0: 0 (to start; we assume the user does not want to quit)
	li	$s1, 0		#s1: index = 0
loop4:	bge	$s1, $s0, finish2	#while (index < digitCt)
	lw	$t1, 0($t0)	#t1: userGuess[i]
	addi	$t0, $t0, 4	#updating the address for the next digit
	addi	$s1, $s1, 1	#index++
	beq	$t1, 0, loop4	#if (userGuess[i] !=0)
	j	finish3		#We are done; the user doesn't want to quit.
finish2:	li	$v0, 1		#The user wants to quit; they entered all zeroes.
	
		
#----------------------- function epilogue  -----------------------	
finish3:	lw	$ra, 0($sp)	#restore the return address	
	lw	$s0, 4($sp)	#restore the value of s0	
	lw	$s1, 8($sp)	#restore the value of s1
	lw	$s2, 12($sp)	#restore the value of s2
	lw	$s3, 16($sp)	#restore the value of s3
	lw	$s4, 20($sp)	#restore the value of s4
	lw	$s5, 24($sp)	#restore the value of s5
	lw	$s6, 28($sp)	#restore the value of s6
	lw	$s7, 32($sp)	#restore the value of s7
	addi	$sp, $sp, 36	#update the stack pointer
	jr	$ra		#return to the calling function
	
	
#--------------------------------------------listReversal--------------------------------------------
		#function that reverses all the elements in a list
		
		#a0: the address of the start of the list in memory we want to swap
		#a1: the number of elements in the list (n)
			
listReversal:								
#----------------------- function preamble  ---------------------------------
        addi	$sp, $sp, -36	#allocate stack space for 9 values	
        sw	$ra, 0($sp)	#store off the return address		
        sw	$s0, 4($sp)	#store off s0		
        sw	$s1, 8($sp)	#store off s1
        sw	$s2, 12($sp)	#store off s2
        sw	$s3, 16($sp)	#store off s3
        sw	$s4, 20($sp)	#store off s4
        sw	$s5, 24($sp)	#store off s5
        sw	$s6, 28($sp)	#store off s6
        sw	$s7, 32($sp)	#store off s7


#-------------------------- function body -------------------------
	move	$a2, $a0		#a2: the address of the start of the list
	move	$s0, $a1		#s0: n
	srl	$s1, $s0, 1	#s1: n / 2 (loop limit)
	li	$s2, 0		#s2: i, index = 0 (index of the first element)
	addi	$s3, $s0, -1	#s3: j, index = n - 1 (index of the second element)

loop5:	bge	$s2, $s1, rest	#while (i < n / 2) 
	# set of call to swap
	move	$a0, $s2		#a0: index of first element for swapping: i
	move	$a1, $s3		#a1: index of second element for swapping: j
	jal	swap		#call the function to swap the elements of userGuess at indices i and j
	addi	$s2, $s2, 1	# i++
	addi	$s3, $s3, -1	# j--
	j	loop5		#return back to the top of the loop to keep swapping numbers in userGuess (if need be)
rest:
	
#----------------------- function epilogue  -----------------------	
	lw	$ra, 0($sp)	#restore the return address	
	lw	$s0, 4($sp)	#restore the value of s0	
	lw	$s1, 8($sp)	#restore the value of s1
	lw	$s2, 12($sp)	#restore the value of s2
	lw	$s3, 16($sp)	#restore the value of s3
	lw	$s4, 20($sp)	#restore the value of s4
	lw	$s5, 24($sp)	#restore the value of s5
	lw	$s6, 28($sp)	#restore the value of s6
	lw	$s7, 32($sp)	#restore the value of s7
	addi	$sp, $sp, 36	#update the stack pointer
	jr	$ra		#return to the calling function
	
	
#-------------------------------------------swap----------------------------------------------
	#function that swaps two numbers in a list in memory
	
	# a0 - index of first element for swapping: i
	# a1 - index of second element for swapping: j
	# a2 - address of the start of the list in memory 

swap:
#----------------------------------function preamble-----------------------
	addi	$sp, $sp, -36	#allocate stack space for 9 values	
        sw	$ra, 0($sp)	#store off the return address		
        sw	$s0, 4($sp)	#store off s0		
        sw	$s1, 8($sp)	#store off s1
        sw	$s2, 12($sp)	#store off s2
        sw	$s3, 16($sp)	#store off s3
        sw	$s4, 20($sp)	#store off s4
        sw	$s5, 24($sp)	#store off s5
        sw	$s6, 28($sp)	#store off s6
        sw	$s7, 32($sp)	#store off s7
        

#----------------------------------function body---------------------------------------
	sll	$s0, $a0, 2	#calc. addr offset of first element
	sll	$s1, $a1, 2	#calc. addr offset of second element
	add	$s0, $s0, $a2	#calc. addr of first element
	add	$s1, $s1, $a2	#calc. addr of second element
	lw	$s2, 0($s0)	#tempi = list[i]
	lw	$s3, 0($s1)	#tempj = list[j]
	sw	$s2, 0($s1)	#list[j] = tempi
	sw	$s3, 0($s0)	#list[i] = tempj

#----------------------- function epilogue  -----------------------	
	lw	$ra, 0($sp)	#restore the return address	
	lw	$s0, 4($sp)	#restore the value of s0	
	lw	$s1, 8($sp)	#restore the value of s1
	lw	$s2, 12($sp)	#restore the value of s2
	lw	$s3, 16($sp)	#restore the value of s3
	lw	$s4, 20($sp)	#restore the value of s4
	lw	$s5, 24($sp)	#restore the value of s5
	lw	$s6, 28($sp)	#restore the value of s6
	lw	$s7, 32($sp)	#restore the value of s7
	addi	$sp, $sp, 36	#update the stack pointer
	jr	$ra		#return to the calling function
	
	
#-----------------------------------------------getFermiCt-------------------------------------------------
		#function that calculates and returns how many "Fermi" responses should be returned to the user
		
		#a0: the address of the start of the list that contains the digits of the user's guess (userGuess)
		#a1: the address of the start of the list that contains the digits of the target number (answer)
		#s2: the number of digits in the target number (digitCt)
				
getFermiCt:						
#----------------------- function preamble  ---------------------------------
        addi	$sp, $sp, -36	#allocate stack space for 9 values	
        sw	$ra, 0($sp)	#store off the return address		
        sw	$s0, 4($sp)	#store off s0		
        sw	$s1, 8($sp)	#store off s1
        sw	$s2, 12($sp)	#store off s2
        sw	$s3, 16($sp)	#store off s3
        sw	$s4, 20($sp)	#store off s4
        sw	$s5, 24($sp)	#store off s5
        sw	$s6, 28($sp)	#store off s6
        sw	$s7, 32($sp)	#store off s7
        

#-------------------------- function body ------------------------- 
	move	$t0, $a0		#t0: the address of the start of userGuess
	move	$t1, $a1		#t1: the address of the start of answer
	move	$s0, $a2		#s0: digitCt
	li	$s1, 0		#s1: running total of the number of "Fermi" responses that the user should receive
	li	$s2, 0		#s2: index = 0
beg:	bge	$s2, $s0, fnsh3	#while (index < digitCt)
	sll	$s3, $s2, 2	#calculating the offset for the two lists
	add	$t2, $t0, $s3	#calculating the address of userGuess[index]
	add	$t3, $t1, $s3	#calculating the address of answer[index]
	lw	$s4, 0($t2)	#s4: userGuess[index]
	lw	$s5, 0($t3)	#s5: answer[index]
	bne	$s4, $s5, mvOn	#if (userGuess[index] == answer[index])
	addi	$s1, $s1, 1	#totalFermiResponses++
mvOn:	addi	$s2, $s2, 1	#index++
	j	beg		#return back to the top of the loop
	
fnsh3:	move	$v0, $s1		#return the number of "Fermi" responses that the user should receive	
	
#----------------------- function epilogue  -----------------------	
	lw	$ra, 0($sp)	#restore the return address	
	lw	$s0, 4($sp)	#restore the value of s0	
	lw	$s1, 8($sp)	#restore the value of s1
	lw	$s2, 12($sp)	#restore the value of s2
	lw	$s3, 16($sp)	#restore the value of s3
	lw	$s4, 20($sp)	#restore the value of s4
	lw	$s5, 24($sp)	#restore the value of s5
	lw	$s6, 28($sp)	#restore the value of s6
	lw	$s7, 32($sp)	#restore the value of s7
	addi	$sp, $sp, 36	#update the stack pointer
	jr	$ra		#return to the calling function
	
	
#-----------------------------------------------getPicoCt-------------------------------------------------
		#function that calculates and returns how many "Pico" responses should be returned to the user
		
		#a0: the address of the start of the list that contains the digits of the user's guess (userGuess)
		#a1: the address of the start of the list that contains the digits of the target number (answer)
		#s2: the number of digits in the target number (digitCt)
				
getPicoCt:						
#----------------------- function preamble  ---------------------------------
        addi	$sp, $sp, -36	#allocate stack space for 9 values	
        sw	$ra, 0($sp)	#store off the return address		
        sw	$s0, 4($sp)	#store off s0		
        sw	$s1, 8($sp)	#store off s1
        sw	$s2, 12($sp)	#store off s2
        sw	$s3, 16($sp)	#store off s3
        sw	$s4, 20($sp)	#store off s4
        sw	$s5, 24($sp)	#store off s5
        sw	$s6, 28($sp)	#store off s6
        sw	$s7, 32($sp)	#store off s7
        

#-------------------------- function body ------------------------- 
	move	$t0, $a0		#t0: the address of the start of userGuess
	move	$t1, $a1		#t1: the address of the start of answer
	move	$s0, $a2		#s0: the number of elements in the lists (n)
	li	$t4, 0		#t4: running total of the number of "Pico" responses the user should receive
	li	$s1, 0		#s1: index = 0
begLp:	bge	$s1, $s0, home	#while (index < n)
	li	$s2, 0		#s2: j = 0
	sll	$t2, $s1, 2	#t2: the offset for finding answer[index]
	add	$t2, $t2, $t1	#t2: the address of answer[index]
	lw	$s3, 0($t2)	#s3: answer[index]
begInLp:	bge	$s2, $s0, incI	#while (j < n)
	sll	$t3, $s2, 2	#t3: the offset for finding userGuess[j]
	add	$t3, $t3, $t0	#t3: the address of userGuess[j]
	lw	$s4, 0($t3)	#s4: userGuess[j]
	bne	$s3, $s4, incJ	#if (answer[index] == userGuess[j])
	beq	$s1, $s2, incJ	#if (index != j)
	addi	$t4, $t4, 1	#totalPicoResponses++
incJ:	addi	$s2, $s2, 1	#j++
	j	begInLp		#return back to the top of the inner loop
incI:	addi	$s1, $s1, 1	#i++
	j	begLp		#return back to the top of the outer loop

home:	move	$v0, $t4		#want to return the number of "Pico" responses the user should receive
	
#----------------------- function epilogue  -----------------------	
	lw	$ra, 0($sp)	#restore the return address	
	lw	$s0, 4($sp)	#restore the value of s0	
	lw	$s1, 8($sp)	#restore the value of s1
	lw	$s2, 12($sp)	#restore the value of s2
	lw	$s3, 16($sp)	#restore the value of s3
	lw	$s4, 20($sp)	#restore the value of s4
	lw	$s5, 24($sp)	#restore the value of s5
	lw	$s6, 28($sp)	#restore the value of s6
	lw	$s7, 32($sp)	#restore the value of s7
	addi	$sp, $sp, 36	#update the stack pointer
	jr	$ra		#return to the calling function
	

#-----------------------------------------------breakUpGuess-------------------------------------------------
		#function that stores the digits of the user's guess backward in a list (userGuess) in memory
		
		#a0: the user's guess
		#a1: the address of the start of the list we want to store the user's guess into (userGuess)
		#a2: the digitCt of the target number
				
breakUpGuess:						
#----------------------- function preamble  ---------------------------------
        addi	$sp, $sp, -36	#allocate stack space for 9 values	
        sw	$ra, 0($sp)	#store off the return address		
        sw	$s0, 4($sp)	#store off s0		
        sw	$s1, 8($sp)	#store off s1
        sw	$s2, 12($sp)	#store off s2
        sw	$s3, 16($sp)	#store off s3
        sw	$s4, 20($sp)	#store off s4
        sw	$s5, 24($sp)	#store off s5
        sw	$s6, 28($sp)	#store off s6
        sw	$s7, 32($sp)	#store off s7
        

#-------------------------- function body ------------------------- 
	move	$s0, $a0		#s0: the current number (which, at the start, is the user's guess)
	move	$t0, $a1		#t0: the address of the start of userGuess
	move	$t3, $a2		#t3: the number of digits in the target number
	li	$s1, 0		#s1: index = 0
	li	$s2, 10		#s2: the register that contains what we will divide the current number by (10)
top:	bge	$s1, $t3, term	#while (index < tarNumDigCt)
	
	div	$s0, $s2		#currentNum / 10
	mfhi	$t1		#t1: the next digit in the user's guess
	mflo	$s0		#s0: the current number without the last digit (which is now the new current number)
	sw	$t1, 0($t0)	#storing the new digit in memory in UserGuess
	addi	$t0, $t0, 4	#updating the address of the next digit we will store into memory
	addi	$s1, $s1, 1	#index++
	j	top		#return back to the top of the loop	
	
#----------------------- function epilogue  -----------------------	
term:	lw	$ra, 0($sp)	#restore the return address	
	lw	$s0, 4($sp)	#restore the value of s0	
	lw	$s1, 8($sp)	#restore the value of s1
	lw	$s2, 12($sp)	#restore the value of s2
	lw	$s3, 16($sp)	#restore the value of s3
	lw	$s4, 20($sp)	#restore the value of s4
	lw	$s5, 24($sp)	#restore the value of s5
	lw	$s6, 28($sp)	#restore the value of s6
	lw	$s7, 32($sp)	#restore the value of s7
	addi	$sp, $sp, 36	#update the stack pointer
	jr	$ra		#return to the calling function
	
	
#----------------------------------------------checkDigitCt-------------------------------------------------
		#function that checks to see if the user inputted the right amount of digits in their guess;
		#if so, returns 1, and if not, returns 0
		
		#a0: the number of digits in the target number
		#a1: the user's guess
				
checkDigitCt:						
#----------------------- function preamble  ---------------------------------
        addi	$sp, $sp, -36	#allocate stack space for 9 values	
        sw	$ra, 0($sp)	#store off the return address		
        sw	$s0, 4($sp)	#store off s0		
        sw	$s1, 8($sp)	#store off s1
        sw	$s2, 12($sp)	#store off s2
        sw	$s3, 16($sp)	#store off s3
        sw	$s4, 20($sp)	#store off s4
        sw	$s5, 24($sp)	#store off s5
        sw	$s6, 28($sp)	#store off s6
        sw	$s7, 32($sp)	#store off s7
        

#-------------------------- function body ------------------------- 
	move	$s0, $a0		#s0: the number of digits in the target number
	move	$s1, $a1		#s1: the user's guess
	
	#calculating the minimum value that a user's input would need to be in order for it to be valid
	li	$s2, 1		#s2: our running total for the minimum value 
	addi	$t0, $s0, -1	#t0: number of digits in the target number - 1
	li	$t1, 0		#t1: our running index for calculating the minimum value
stOfLp:	bge	$t1, $t0, brnch	#while (index < targetNumberDigitCt - 1)
	mul	$s2, $s2, 10	#updating the minimum value by finding 10^(targetNumDigitCt - 1)
	addi	$t1, $t1, 1	#index++
	j 	stOfLp		#return back to the start of the loop to keep multiplying by 10 (if need be)
	
	#At this point, we know s2 contains the minimum value of a valid user input
	#checking to see if the user inputted a value less than s2
brnch:	bge	$s1, $s2, goMore	#if (userGuess < minimum valid value)
	li	$v0, 0		#want to return 0
	j	term1		#we are done
 		
goMore:	#calculating the first integer greater than the biggest valid user input 
	mul	$s2, $s2, 10	#s2: the first integer greater than the biggest valid user input
	
	#checking to see if the user inputted a value greater than or equal to s2
	blt	$s1, $s2, endIt	#if (userGuess >= smallest integer greater than all legal input values
	li	$v0, 0		#want to return 0
	j	term1		#we are done

	#At this point, we know the user inputted the right amount of digits.
	#So, we want to return 1.
endIt: li	$v0, 1		#want to return 1
	
#----------------------- function epilogue  -----------------------	
term1:	lw	$ra, 0($sp)	#restore the return address	
	lw	$s0, 4($sp)	#restore the value of s0	
	lw	$s1, 8($sp)	#restore the value of s1
	lw	$s2, 12($sp)	#restore the value of s2
	lw	$s3, 16($sp)	#restore the value of s3
	lw	$s4, 20($sp)	#restore the value of s4
	lw	$s5, 24($sp)	#restore the value of s5
	lw	$s6, 28($sp)	#restore the value of s6
	lw	$s7, 32($sp)	#restore the value of s7
	addi	$sp, $sp, 36	#update the stack pointer
	jr	$ra		#return to the calling function
	
	