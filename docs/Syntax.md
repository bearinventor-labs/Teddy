# Teddy Syntax Documentation v1.0

## Table of Contents

* [Keywords](#keywords)
* [Variables](#variables)
    * [Variable Types](#variable-types)
    * [Variable Modifications](#variable-modifications)
* [Comments](#comments)

## Keywords

Keywords provide commands to be translated into system-wide functions OR assembly commands.

### Assembly Keywords

- **Reserve** Denoted with the 'res' at the beginning of the statement. MUST be followed with the following in order: variable, operator 'w/','()' with given values of hexadecimal, string, or number, and ';' to end the statement.
```teddy
res $variableName w/ (10);
```

## Variables

Variables provide 3 different storage styles. A standard variable is storaged anywhere in memory. A registry variable is storaged directly into a CPU registry. A priority variable is storaged in a specific address of RAM. ALL variables must use standard lowercase and uppercase alphabetic for names.

### Variable Types

- **Variable** Denoted with the "$" at the beginning of the variable name.  
```teddy
$variableName
```
- **Priority Variable** Denoted with the '!$' at the beginning of the variable name. MUST be followed with '()' AFTER any variable modifications to determine the memory address in hexadecimal. 
```teddy
!$variableName(0xB8700)
```
- **Registry Variable** Denoted with the '^$' at the beginning of the variable name. MUST be followed with '()' AFTER any variable modifications to determine the CPU registry in assembly. 
```teddy
^$variableName(al)
```

### Variable Modifications

- **Byte** Denoted with the ':b' at the end of the variable name and variable addressing.
```teddy
$variableName:b
```
- **Word** Denoted with the ':w' at the end of the variable name and variable addressing.
```teddy
$variableName:w
```

## Logic

## Functions

## Conditions

## Operations

## Numbers

## Comments

- **Comments** Denoted with the '#' at the beginning of the comment. ALL characters of any type are considered a comment UNTIL the next line. 
```teddy
$variable # This is the comment.
$variabletwo
```