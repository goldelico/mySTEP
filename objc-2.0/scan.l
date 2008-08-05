/* ObjC-2.0 scanner - based on http://www.lysator.liu.se/c/ANSI-C-grammar-l.html */

	/* digit */
D			[0-9]
	/* letter */
L			[a-zA-Z_]
	/* hex letter */
H			[a-fA-F0-9]
	/* exponent */
E			[Ee][+-]?{D}+
	/* float suffix */
FS			(f|F|l|L)
	/* int suffix */
IS			(u|U|l|L)*

%{
#include <stdio.h>
#include "y.tab.h"
	
#define error(X)
	
void count();

int column = 0;
int line = 1;	
	
%}

%%

"/*"			{ comment(); }
 
 /* note: we should recognize as keyword, i.e. autobreak is a single IDENTIFIER and not 2 keywords */
 
 "auto"			{ count(); return(AUTO); }
 "break"		{ count(); return(BREAK); }
 "case"			{ count(); return(CASE); }
 "char"			{ count(); return(CHAR); }
 "const"		{ count(); return(CONST); }
 "continue"		{ count(); return(CONTINUE); }
 "default"		{ count(); return(DEFAULT); }
 "do"			{ count(); return(DO); }
 "double"		{ count(); return(DOUBLE); }
 "else"			{ count(); return(ELSE); }
 "enum"			{ count(); return(ENUM); }
 "extern"		{ count(); return(EXTERN); }
 "float"		{ count(); return(FLOAT); }
 "for"			{ count(); return(FOR); }
 "goto"			{ count(); return(GOTO); }
 "if"			{ count(); return(IF); }
 "int"			{ count(); return(INT); }
 "long"			{ count(); return(LONG); }
 "register"		{ count(); return(REGISTER); }
 "return"		{ count(); return(RETURN); }
 "short"		{ count(); return(SHORT); }
 "signed"		{ count(); return(SIGNED); }
 "sizeof"		{ count(); return(SIZEOF); }
 "static"		{ count(); return(STATIC); }
 "struct"		{ count(); return(STRUCT); }
 "switch"		{ count(); return(SWITCH); }
 "typedef"		{ count(); return(TYPEDEF); }
 "union"		{ count(); return(UNION); }
 "unsigned"		{ count(); return(UNSIGNED); }
 "void"			{ count(); return(VOID); }
 "volatile"		{ count(); return(VOLATILE); }
 "while"			{ count(); return(WHILE); }
 
 /* gcc extensions */
 
 /* Obj-C 1.0 extensions */
 
 "//"						{ commentplusplus(); }
 "@interface"				{ count(); return(AT_INTERFACE); }
 "@implementation"			{ count(); return(AT_IMPLEMENTATION); }
 "@end"						{ count(); return(AT_END); }
 "@class"					{ count(); return(AT_CLASS); }
 "@protocol"				{ count(); return(AT_PROTOCOL); }
 "@selector"				{ count(); return(AT_SELECTOR); }
 "@encode"					{ count(); return(AT_ENCODE); }
 "@catch"					{ count(); return(AT_CATCH); }
 "@try"						{ count(); return(AT_TRY); }
 "@protected"				{ count(); return(AT_PROTECTED); }
 "@private"					{ count(); return(AT_PRIVATE); }
 "@public"					{ count(); return(AT_PUBLIC); }
 "inout"					{ count(); return(INOUT); }
 "in"						{ count(); return(IN); }
 "out"						{ count(); return(OUT); }
 "byref"					{ count(); return(BYREF); }
 "bycopy"					{ count(); return(BYCOPY); }
 "oneway"					{ count(); return(ONEWAY); }
 
 /* fixme - we should know how to distinguish identifiers from types */

 "id"						{ count(); return(ID); }
 "SEL"						{ count(); return(SEL); }
 "BOOL"						{ count(); return(BOOL); }
 "unichar"					{ count(); return(UNICHAR); }
 "Class"					{ count(); return(CLASS); }
 
 @\"(\\.|[^\\"])*\"			{ count(); yylval.string=strdup(yytext); return(AT_STRING_LITERAL); }
 
 /* Obj-C 2.0 extensions */
 
 "@property"				{ count(); return(AT_PROPERTY); }
 "@synthesize"				{ count(); return(AT_SYNTHESIZE); }
 "@optional"				{ count(); return(AT_OPTIONAL); }
 "@required"				{ count(); return(AT_REQUIRED); }
 "__weak"					{ count(); return(WEAK); }
 "__strong"					{ count(); return(STRONG); }
  
 L(L)*				{ count(); yylval.string=strdup(yytext); return(IDENTIFIER); }
 {L}({L}|{D})*		{ count(); yylval.string=strdup(yytext); return(IDENTIFIER); }
 
0[xX]{H}+{IS}?		{ count(); yylval.string=strdup(yytext); return(CONSTANT); }
0{D}+{IS}?			{ count(); yylval.string=strdup(yytext); return(CONSTANT); }
{D}+{IS}?			{ count(); yylval.string=strdup(yytext); return(CONSTANT); }
L?'(\\.|[^\\'])+'	{ count(); yylval.string=strdup(yytext); return(CONSTANT); }
 
{D}+{E}{FS}?		{ count(); yylval.string=strdup(yytext); return(CONSTANT); }
{D}*"."{D}+({E})?{FS}?	{ count(); yylval.string=strdup(yytext); return(CONSTANT); }
{D}+"."{D}*({E})?{FS}?	{ count(); yylval.string=strdup(yytext); return(CONSTANT); }
 
L?\"(\\.|[^\\"])*\"	{ count(); yylval.string=strdup(yytext); return(STRING_LITERAL); }
 
"..."			{ count(); return(ELLIPSIS); }
">>="			{ count(); return(RIGHT_ASSIGN); }
"<<="			{ count(); return(LEFT_ASSIGN); }
"+="			{ count(); return(ADD_ASSIGN); }
"-="			{ count(); return(SUB_ASSIGN); }
"*="			{ count(); return(MUL_ASSIGN); }
"/="			{ count(); return(DIV_ASSIGN); }
"%="			{ count(); return(MOD_ASSIGN); }
"&="			{ count(); return(AND_ASSIGN); }
 "^="			{ count(); return(XOR_ASSIGN); }
 "|="			{ count(); return(OR_ASSIGN); }
 ">>"			{ count(); return(RIGHT_OP); }
 "<<"			{ count(); return(LEFT_OP); }
 "++"			{ count(); return(INC_OP); }
 "--"			{ count(); return(DEC_OP); }
 "->"			{ count(); return(PTR_OP); }
 "&&"			{ count(); return(AND_OP); }
 "||"			{ count(); return(OR_OP); }
 "<="			{ count(); return(LE_OP); }
 ">="			{ count(); return(GE_OP); }
 "=="			{ count(); return(EQ_OP); }
 "!="			{ count(); return(NE_OP); }
 ";"			{ count(); return(';'); }
 ("{"|"<%")		{ count(); return('{'); }
 ("}"|"%>")		{ count(); return('}'); }
 ","			{ count(); return(','); }
 ":"			{ count(); return(':'); }
 "="			{ count(); return('='); }
 "("			{ count(); return('('); }
 ")"			{ count(); return(')'); }
 ("["|"<:")		{ count(); return('['); }
 ("]"|":>")		{ count(); return(']'); }
 "."			{ count(); return('.'); }
 "&"			{ count(); return('&'); }
 "!"			{ count(); return('!'); }
 "~"			{ count(); return('~'); }
 "-"			{ count(); return('-'); }
 "+"			{ count(); return('+'); }
 "*"			{ count(); return('*'); }
 "/"			{ count(); return('/'); }
 "%"			{ count(); return('%'); }
 "<"			{ count(); return('<'); }
 ">"			{ count(); return('>'); }
 "^"			{ count(); return('^'); }
 "|"			{ count(); return('|'); }
 "?"			{ count(); return('?'); }
 
 [\n]			{ line++, column=0; }
 [ \t\v\f]		{ count(); }
 
 .				{ count(); error( "bad character" ); }

%%
 
 int yywrap()
 {
	 return(1);
 }
 
 
 void comment()
 {
	 char c;
	 while ( 1 )
		 {
		 while ( (c = input()) != '*' && c != EOF )
			 { /* eat up text of comment */
			 if(c == '\n')
				 line++;
			 }
		 if ( c == '*' )
			 {
			 while ( (c = input()) == '*' )
				 ;
			 if ( c == '/' )
				 break;    /* found the end */
			 }
		 
		 if ( c == EOF )
			 {
			 error( "EOF in comment" );
			 break;
			 }
		 }
 }
 
void commentplusplus()
 {
	 char c;	 
	 while ((c = input()) != '\n' && c != 0)
		 /*putchar(c)*/;
 }
 
 
 void count()
 {
	 int i;
	 
	 for (i = 0; yytext[i] != '\0'; i++)
		 if (yytext[i] == '\n')
			 column = 0;
		 else if (yytext[i] == '\t')
			 column += 8 - (column % 8);
		 else
			 column++;
	 
//	 ECHO;
 }

char *strdup(char *str)
{ // copy
	char r=(char *) malloc(strlen(str)+1);
	strcpy(r, str);
	return r;
}

char *strdupcat(char *str1, char *str2)
{ // catenate into a copy
	char r=(char *) malloc(strlen(str1)+strlen(str2)+1);
	strcpy(r, str1);
	strcat(r, str2);
	return r;
}

char *strdupcat3(char *str1, char *str2, char *str3)
{ // catenate into a copy
	char r=(char *) malloc(strlen(str1)+strlen(str2)+strlen(str3)+1);
	strcpy(r, str1);
	strcat(r, str2);
	strcat(r, str3);
	return r;
}
