/* A Bison parser, made by GNU Bison 2.3.  */

/* Skeleton interface for Bison's Yacc-like parsers in C

   Copyright (C) 1984, 1989, 1990, 2000, 2001, 2002, 2003, 2004, 2005, 2006
   Free Software Foundation, Inc.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* Tokens.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
   /* Put the tokens into the symbol table, so that GDB and other debuggers
      know about them.  */
   enum yytokentype {
     SIZEOF = 258,
     PTR_OP = 259,
     INC_OP = 260,
     DEC_OP = 261,
     LEFT_OP = 262,
     RIGHT_OP = 263,
     LE_OP = 264,
     GE_OP = 265,
     EQ_OP = 266,
     NE_OP = 267,
     AND_OP = 268,
     OR_OP = 269,
     MUL_ASSIGN = 270,
     DIV_ASSIGN = 271,
     MOD_ASSIGN = 272,
     ADD_ASSIGN = 273,
     SUB_ASSIGN = 274,
     LEFT_ASSIGN = 275,
     RIGHT_ASSIGN = 276,
     AND_ASSIGN = 277,
     XOR_ASSIGN = 278,
     OR_ASSIGN = 279,
     TYPEDEF = 280,
     EXTERN = 281,
     STATIC = 282,
     AUTO = 283,
     REGISTER = 284,
     CHAR = 285,
     SHORT = 286,
     INT = 287,
     LONG = 288,
     SIGNED = 289,
     UNSIGNED = 290,
     FLOAT = 291,
     DOUBLE = 292,
     CONST = 293,
     VOLATILE = 294,
     VOID = 295,
     STRUCT = 296,
     UNION = 297,
     ENUM = 298,
     ELLIPSIS = 299,
     CASE = 300,
     DEFAULT = 301,
     IF = 302,
     ELSE = 303,
     SWITCH = 304,
     WHILE = 305,
     DO = 306,
     FOR = 307,
     GOTO = 308,
     CONTINUE = 309,
     BREAK = 310,
     RETURN = 311,
     ID = 312,
     SEL = 313,
     BOOL = 314,
     UNICHAR = 315,
     CLASS = 316,
     AT_CLASS = 317,
     AT_PROTOCOL = 318,
     AT_INTERFACE = 319,
     AT_IMPLEMENTATION = 320,
     AT_END = 321,
     AT_PRIVATE = 322,
     AT_PUBLIC = 323,
     AT_PROTECTED = 324,
     AT_SELECTOR = 325,
     AT_ENCODE = 326,
     AT_CATCH = 327,
     AT_THROW = 328,
     AT_TRY = 329,
     IN = 330,
     OUT = 331,
     INOUT = 332,
     BYREF = 333,
     BYCOPY = 334,
     ONEWAY = 335,
     AT_PROPERTY = 336,
     AT_SYNTHESIZE = 337,
     AT_OPTIONAL = 338,
     AT_REQUIRED = 339,
     WEAK = 340,
     STRONG = 341,
     IDENTIFIER = 342,
     TYPE_NAME = 343,
     CONSTANT = 344,
     STRING_LITERAL = 345,
     AT_STRING_LITERAL = 346
   };
#endif
/* Tokens.  */
#define SIZEOF 258
#define PTR_OP 259
#define INC_OP 260
#define DEC_OP 261
#define LEFT_OP 262
#define RIGHT_OP 263
#define LE_OP 264
#define GE_OP 265
#define EQ_OP 266
#define NE_OP 267
#define AND_OP 268
#define OR_OP 269
#define MUL_ASSIGN 270
#define DIV_ASSIGN 271
#define MOD_ASSIGN 272
#define ADD_ASSIGN 273
#define SUB_ASSIGN 274
#define LEFT_ASSIGN 275
#define RIGHT_ASSIGN 276
#define AND_ASSIGN 277
#define XOR_ASSIGN 278
#define OR_ASSIGN 279
#define TYPEDEF 280
#define EXTERN 281
#define STATIC 282
#define AUTO 283
#define REGISTER 284
#define CHAR 285
#define SHORT 286
#define INT 287
#define LONG 288
#define SIGNED 289
#define UNSIGNED 290
#define FLOAT 291
#define DOUBLE 292
#define CONST 293
#define VOLATILE 294
#define VOID 295
#define STRUCT 296
#define UNION 297
#define ENUM 298
#define ELLIPSIS 299
#define CASE 300
#define DEFAULT 301
#define IF 302
#define ELSE 303
#define SWITCH 304
#define WHILE 305
#define DO 306
#define FOR 307
#define GOTO 308
#define CONTINUE 309
#define BREAK 310
#define RETURN 311
#define ID 312
#define SEL 313
#define BOOL 314
#define UNICHAR 315
#define CLASS 316
#define AT_CLASS 317
#define AT_PROTOCOL 318
#define AT_INTERFACE 319
#define AT_IMPLEMENTATION 320
#define AT_END 321
#define AT_PRIVATE 322
#define AT_PUBLIC 323
#define AT_PROTECTED 324
#define AT_SELECTOR 325
#define AT_ENCODE 326
#define AT_CATCH 327
#define AT_THROW 328
#define AT_TRY 329
#define IN 330
#define OUT 331
#define INOUT 332
#define BYREF 333
#define BYCOPY 334
#define ONEWAY 335
#define AT_PROPERTY 336
#define AT_SYNTHESIZE 337
#define AT_OPTIONAL 338
#define AT_REQUIRED 339
#define WEAK 340
#define STRONG 341
#define IDENTIFIER 342
#define TYPE_NAME 343
#define CONSTANT 344
#define STRING_LITERAL 345
#define AT_STRING_LITERAL 346




#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef int YYSTYPE;
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
# define YYSTYPE_IS_TRIVIAL 1
#endif

extern YYSTYPE yylval;

