// Copyright 2013 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// This is an example of a goyacc program.
// To build it:
// goyacc -p "expr" expr.y (produces y.go)
// go build -o expr y.go
// expr
// > <type an expression>

%{

package main

import (
	"bytes"
	"fmt"
	"log"
	"math/big"
	"unicode/utf8"
)

%}

%union {
	num *big.Rat
}

%type	<num>	cal

%right '+' '-'
%right '*' '/'
%token '(' ')'

%token	<num>	NUM

%%

top:
	cal
	{
		if $1.IsInt() {
			fmt.Println($1.Num().String())
		} else {
			fmt.Println($1.String())
		}
	}

cal:
       '(' cal ')'
        {
           $$ = $2
        }
     | cal '+' cal
        {
           $$ = $1.Add($1, $3)
        }

     | cal '-' cal
        {
          $$ = $1.Sub($1, $3)
        }
     | cal '*' cal
       {
          $$ = $1.Mul($1, $3)
       }
     | cal '/' cal
       {
          $$ = $1.Quo($1, $3)
       }
     | '-' cal %prec '*'
       {
          $$ = $2.Neg($2)
       }
     | NUM

%%

// The parser expects the lexer to return 0 on EOF.  Give it a name
// for clarity.
const eof = 0

// The parser uses the type <prefix>Lex as a lexer. It must provide
// the methods Lex(*<prefix>SymType) int and Error(string).
type calLex struct {
	line []byte
	peek rune
}

// The parser calls this method to get each new token. This
// implementation returns operators and NUM.
func (x *calLex) Lex(yylval *calSymType) int {
	for {
		c := x.next()
		switch c {
		case eof:
			return eof
		case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9':
			return x.num(c, yylval)
		case '+', '-', '*', '/', '(', ')':
			return int(c)

		// Recognize Unicode multiplication and division
		// symbols, returning what the parser expects.
		case '×':
			return '*'
		case '÷':
			return '/'

		case ' ', '\t', '\n', '\r':
		default:
			log.Printf("unrecognized character %q", c)
		}
	}
}

// Lex a number.
func (x *calLex) num(c rune, yylval *calSymType) int {
	add := func(b *bytes.Buffer, c rune) {
		if _, err := b.WriteRune(c); err != nil {
			log.Fatalf("WriteRune: %s", err)
		}
	}
	var b bytes.Buffer
	add(&b, c)
	L: for {
		c = x.next()
		switch c {
		case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.', 'e', 'E':
			add(&b, c)
		default:
			break L
		}
	}
	if c != eof {
		x.peek = c
	}
	yylval.num = &big.Rat{}
	_, ok := yylval.num.SetString(b.String())
	if !ok {
		log.Printf("bad number %q", b.String())
		return eof
	}
	return NUM
}

// Return the next rune for the lexer.
func (x *calLex) next() rune {
	if x.peek != eof {
		r := x.peek
		x.peek = eof
		return r
	}
	if len(x.line) == 0 {
		return eof
	}
	c, size := utf8.DecodeRune(x.line)
	x.line = x.line[size:]
	if c == utf8.RuneError && size == 1 {
		log.Print("invalid utf8")
		return x.next()
	}
	return c
}

// The parser calls this method on a parse error.
func (x *calLex) Error(s string) {
	log.Printf("parse error: %s", s)
}
