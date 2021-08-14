<br />
<p align="center">
  <a href="https://github.com/naderabdalghani/kabsa">
    <img src="gui/assets/icon.png" alt="Logo" width="80" height="80">
  </a>

  <h3 align="center">kabsa</h3>

  <p align="center">
    A compiler built using Bison & Flex C++ interfaces that generates code for a hypothetical stack-based machine
  </p>
</p>

## Table of Contents

- [About the Project](#about-the-project)
  - [Example Test Cases](#example-test-cases)
    - [if-else statements](#if-else-statements)
    - [Loops](#loops)
    - [Expressions](#expressions)
    - [Functions](#functions)
    - [Enums](#enums)
    - [Enums Error](#enums-error)
    - [Semantic Errors](#semantic-errors)
    - [Syntax Errors](#syntax-errors)
  - [Output Quadruples](#output-quadruples)
  - [Future Plans](#future-plans)
  - [Built With](#built-with)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Running](#running)
- [Acknowledgements](#acknowledgements)

## About The Project

Instead of using Bison and Flex C interfaces, or even use the C interfaces and compile them using a C++ compiler, this compiler was built using both [Bison and Flex C++ interfaces](http://westes.github.io/flex/manual/Cxx.html#Cxx).

### Example Test Cases

#### _if-else statements_

[`if.kabsa`](examples/if.kabsa):

```js
function main() {
  x = 10;
  b;
  if (x == 10) {
    b = 10;
  } else if (x == 5) {
    b = 5;
  } else {
    b = x;
  }
}
```

`if.asm`:

```c
	PROC	main
	PUSH	10
	POP     x
	PUSH	b
	PUSH	x
	PUSH	10
	CMPEQ
	JNZ	L0000
	PUSH	10
	POP     b
	JMP	L0001
L0000:
	PUSH	x
	PUSH	5
	CMPEQ
	JNZ	L0002
	PUSH	5
	POP     b
	JMP	L0003
L0002:
	PUSH	x
	POP     b
L0003:
L0001:
	ENDP	main
```

Symbol Table:

| Variable |   Type   | Initialized |
| :------: | :------: | :---------: |
|   main   | function |      1      |
|    b     | variable |      1      |
|    x     | variable |      1      |

---

#### _Loops_

[`loops.kabsa`](examples/loops.kabsa):

```js
function main() {
  for (i = 0; i < 10; i = i + 1) {
    b = 10;
  }

  x = 0;

  while (x < 20) {
    x = x + 1;
  }

  x = 0;

  do {
    x = x + 1;
  } while (x < 20);

  switch (x) {
    case 1:
      x = 10;
      break;

    default:
      break;
  }
}
```

`loops.asm`:

```c
	PROC	main
	PUSH	0
	POP     i
L0000:
	PUSH	i
	PUSH	10
	CMPLT
	JNZ	L0001
	PUSH	10
	POP     b
	PUSH	i
	PUSH	1
	ADD
	POP     i
	JMP	L0000
L0001:
	PUSH	0
	POP     x
L0002:
	PUSH	x
	PUSH	20
	CMPLT
	JNZ	L0003
	PUSH	x
	PUSH	1
	ADD
	POP     x
	JMP	L0002
L0003:
	PUSH	0
	POP     x
L0004:
	PUSH	x
	PUSH	1
	ADD
	POP     x
	PUSH	x
	PUSH	20
	CMPLT
	JZ	L0004
	PUSH	x
	PUSH	1
	CMPEQ
	JZ	L0005
	JMP	L0006
L0005:
	PUSH	10
	POP     x
	JMP	L0007
L0006:
	JMP	L0007
L0007:
	ENDP	main
```

Symbol Table:

| Variable |   Type   | Initialized |
| :------: | :------: | :---------: |
|   main   | function |      1      |
|    x     | variable |      1      |
|    b     | variable |      1      |
|    i     | variable |      1      |

---

#### _Expressions_

[`expressions.kabsa`](examples/expressions.kabsa):

```js
function main() {
  x = 0;
  y = 10;
  z = x / y - x;
  a = true;
  b = false;
  c = a & b;
}
```

`expressions.asm`:

```c
	PROC	main
	PUSH	0
	POP     x
	PUSH	10
	POP     y
	PUSH	x
	PUSH	y
	DIV
	PUSH	x
	SUB
	POP     z
	PUSH	1
	POP     a
	PUSH	0
	POP     b
	PUSH	a
	PUSH	b
	AND
	POP     c
	ENDP	main
```

Symbol Table:

| Variable |   Type   | Initialized |
| :------: | :------: | :---------: |
|    c     | variable |      1      |
|    b     | variable |      1      |
|    a     | variable |      1      |
|   main   | function |      1      |
|    z     | variable |      1      |
|    y     | variable |      1      |
|    x     | variable |      1      |

---

#### _Functions_

[`function.kabsa`](examples/function.kabsa):

```js
function sum(x, y) {
  return x + y;
}

function main() {
  a = sum(10, 20);
  a = sum(a, a);
}
```

`function.asm`:

```c
	PROC	sum
	POP     x
	POP     y
	POP     x
	POP     y
	ADD
	RET
	ENDP	sum
	PROC	main
	PUSH	20
	PUSH	10
	CALL	sum
	POP     a
	PUSH	a
	PUSH	a
	CALL	sum
	POP     a
	ENDP	main
```

Symbol Table:

| Variable |   Type   | Initialized |
| :------: | :------: | :---------: |
|   main   | function |      1      |
|    a     | variable |      1      |
|   sum    | function |      1      |
|    y     | variable |      1      |
|    x     | variable |      1      |

---

#### _Enums_

[`enums.kabsa`](examples/enums.kabsa):

```js
function main()
{
  enum day_of_the_week
  {
    Mon,
    Sun
  };
  x = Mon;
}
```

`enums.asm`:

```c
	PROC	main
	PUSH	0
	POP     Mon
	PUSH	1
	POP     Sun
	PUSH	Mon
	POP     x
	ENDP	main
```

Symbol Table:

|    Variable     |         Type         | Initialized |
| :-------------: | :------------------: | :---------: |
|      main       |       function       |      1      |
|        x        |       variable       |      1      |
| day_of_the_week | enumerator specifier |      1      |
|       Sun       |      enumerator      |      1      |
|       Mon       |      enumerator      |      1      |

---

#### _Enums Error_

[`enums-error.kabsa`](examples/enums-error.kabsa):

```js
function main()
{
  enum day_of_the_week
  {
    Mon,
    Sun
  };
  x = Tue;
}
```

Error Message:

`8.11: Undeclared variable used`

---

#### _Semantic Errors_

[`semantic-error.kabsa`](examples/semantic-error.kabsa):

```js
function main() {
  const x = 10;
  a = 9;
  x = a;
}
```

Error Message:

`5.9: Cannot reassign value to constant variable`

---

#### _Syntax Errors_

[`syntax-error.kabsa`](examples/syntax-error.kabsa):

```js
function main()
{
  2s = 10;
}
```

Error Message:

`3.4: syntax error, unexpected INTEGER`

---

### Output Quadruples

|   Quadruple    |                                                            Description                                                            |
| :------------: | :-------------------------------------------------------------------------------------------------------------------------------: |
|     PUSH X     |                                                         Pushes X to stack                                                         |
|     POP X      |                                                  Pop the top stack value into X                                                   |
|     CMPLT      |       Pops two values from the stack and sets the Z flag to 1 if the older value in the stack is less than the newer value        |
|     CMPLE      |  Pops two values from the stack and sets the Z flag to 1 if the older value in the stack is less or equals than the newer value   |
|     CMPNE      |                           Pops two values from the stack and sets the Z flag to 1 if they are not equal                           |
|     CMPGT      |      Pops two values from the stack and sets the Z flag to 1 if the older value in the stack is greater than the newer value      |
|     CMPGE      | Pops two values from the stack and sets the Z flag to 1 if the older value in the stack is greater than or equals the newer value |
|     CMPEQ      |                             Pops two values from the stack and sets the Z flag to 1 if they are equal                             |
|      ADD       |                              Pops two value from the stack and pushes their summation onto the stack                              |
|      SUB       |                             Pops two value from the stack and pushes their subtraction onto the stack                             |
|      MUL       |                           Pops two value from the stack and pushes their multiplication onto the stack                            |
|      DIV       |                              Pops two value from the stack and pushes their division onto the stack                               |
|      NEG       |                                Pops a value from the stack and pushes its negation onto the stack                                 |
|      AND       |                           Pops two value from the stack (and them) and pushes the result onto the stack                           |
|       OR       |                           Pops two value from the stack (or them) and pushes the result onto the stack                            |
|      NOT       |                             Pops a value from the stack (not it) and pushes the result onto the stack                             |
|   JMP LABEL    |                                                    Unconditional jump to LABEL                                                    |
|   JNZ LABEL    |                                                      Jump if zero flag == 0                                                       |
|    JZ LABEL    |                                                      Jump if zero flag == 1                                                       |
| PROC PROC_NAME |                                     Starts procedure/function with name PROC_NAME definition                                      |
| ENDP PROC_NAME |                                       End procedure/function with name PROC_NAME definition                                       |
| CALL PROC_NAME |      Calls procedure/function with name PROC_NAME, if there are arguments for this function they are pushed into stack first      |
|      RET       |    Return from function call to execute the next line of the code, if the function returns value then it is pop from the tack     |

### Future Plans

- Rigorously test nested and combined code structures
- Modify the Lexer to scan arabic patters
- Implement symbol tables for different scopes
- Scan and parse more code artifacts (e.g comments, classes, etc.)

### Built With

- [Cygwin g++ compiler](https://www.cygwin.com/)
- [winflexbison](https://github.com/lexxmark/winflexbison)
- [Python 3.9 (including Tkinter for GUI)](https://www.python.org/downloads/release/python-390/)

## Getting Started

### Prerequisites

- Setup Python using this [link](https://realpython.com/installing-python/)
- Download [winflexbison](https://github.com/lexxmark/winflexbison/releases/) and extract the zipped file content straight into the C drive so you’d end up with a directory similar to the following directory `C:\win_flex_bison-*.*.*`
- Setup Cygwin g++ compiler
- Add `C:\win_flex_bison-*.*.*` and `C:\cygwin64\bin` to your environment variables system path

### Running

- Run the following commands to compile a compiler executable:

  - `win_bison -d parser.yy`

    - `win_flex scanner.l`
    - `g++ -I C:\win_flex_bison-2.5.24 main.cc driver.cc lex.kabsa.cc parser.tab.cc`

    Where `win_flex_bison-2.5.24` is the name of the winflexbison directory in the C drive

- Run the following command to compile a .kabsa code file:

  `.\a.exe "<input file path>" "<output directory>"`

  - Example:

    `.\a.exe "D:/examples/if.kabsa" "D:/examples_output"`

  Where `a.exe` is kabsa compiler executable output from the `g++` compilation command

- To run using the GUI:

  - Copy the compiler executable `a.exe` to the gui directory and name it `compiler.exe`
  - Run the GUI using the following command in the `/gui` directory: `python gui.py`

## Acknowledgements

- [sanwade — Flex Bison & Yacc Tutorial (With Code and Example)](https://www.youtube.com/playlist?list=PLIrl0f9NJZy4oOOAVPU6MyRdFjJFGtceu)
- [Jonathan Engelsma — Tutorial: programming with lex/yacc](https://www.youtube.com/playlist?list=PLkB3phqR3X43IRqPT0t1iBfmT5bvn198Z)
- [IBM — Abstract for Programming Tools](https://www.ibm.com/docs/en/zos/2.4.0?topic=services-zos-unix-system-programming-tools)
- [ANSI C Yacc grammar](https://www.lysator.liu.se/c/ANSI-C-grammar-y.html)
- [jonathan-beard/simple_wc_example](https://github.com/jonathan-beard/simple_wc_example)
- [Base64 File Converter Tkinter Template](https://homework.nwsnet.de/releases/5d28/)
