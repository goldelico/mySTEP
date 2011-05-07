/* ObjC-2.0 scanner - based on http://www.lysator.liu.se/c/ANSI-C-grammar-y.html */
/* part of objc2pp - an obj-c 2 preprocessor */

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "node.h"
%}

%token SIZEOF PTR_OP INC_OP DEC_OP LEFT_OP RIGHT_OP LE_OP GE_OP EQ_OP NE_OP
%token AND_OP OR_OP MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN
%token SUB_ASSIGN LEFT_ASSIGN RIGHT_ASSIGN AND_ASSIGN
%token XOR_ASSIGN OR_ASSIGN 

%token TYPEDEF EXTERN STATIC AUTO REGISTER
%token CHAR SHORT INT LONG SIGNED UNSIGNED FLOAT DOUBLE CONST VOLATILE VOID
%token STRUCT UNION ENUM ELLIPSIS

%token CASE DEFAULT IF ELSE SWITCH WHILE DO FOR GOTO CONTINUE BREAK RETURN

%token ID SEL BOOL UNICHAR CLASS
%token AT_CLASS AT_PROTOCOL AT_INTERFACE AT_IMPLEMENTATION AT_END
%token AT_PRIVATE AT_PUBLIC AT_PROTECTED
%token AT_SELECTOR AT_ENCODE
%token AT_CATCH AT_THROW AT_TRY
%token IN OUT INOUT BYREF BYCOPY ONEWAY

%token AT_PROPERTY AT_SYNTHESIZE AT_OPTIONAL AT_REQUIRED WEAK STRONG

%token IDENTIFIER
%token TYPE_NAME
%token CONSTANT
%token STRING_LITERAL
%token AT_STRING_LITERAL

%start translation_unit

%%

// define result type for each expansion

// FIXME: it is not oly an IDENTIFIER but any keyword is allowed!

selector_component
	: IDENTIFIER ':' {  }
	| ':' {  }
	;

selector_with_arguments
	: IDENTIFIER { $$ = $1; }
	| IDENTIFIER ':' expression  {  }
	| selector_with_arguments selector_component expression {  }
	| selector_with_arguments ',' ELLIPSIS  {  }
	;

struct_component_expression
	: conditional_expression
	| struct_component_expression conditional_expression
	;

selector
	: IDENTIFIER
	| ':' { }
	| IDENTIFIER ':'
	| selector ':'
	;

primary_expression
	: IDENTIFIER
	| CONSTANT
	| STRING_LITERAL
	| '(' expression ')'
	| AT_STRING_LITERAL
	| '[' expression selector_with_arguments ']'
	| AT_SELECTOR '(' selector ')'
	| AT_ENCODE '(' type_name ')'
	;

postfix_expression
	: primary_expression
	| postfix_expression '[' expression ']'
	| postfix_expression '(' ')'
	| postfix_expression '(' argument_expression_list ')'
	| postfix_expression '.' IDENTIFIER
		{
		/* if expression is object, replace by [object valueForKey:@"path.path."] - or setValue if we are part of an LValue */
		}
	| postfix_expression PTR_OP IDENTIFIER
	| postfix_expression INC_OP
	| postfix_expression DEC_OP
	;

argument_expression_list
	: assignment_expression
	| argument_expression_list ',' assignment_expression
	;

unary_expression
	: postfix_expression
	| INC_OP unary_expression { $$=node(INC_OP, $2, 0); }
	| DEC_OP unary_expression { $$=node(DEC_OP, $2, 0); }
	| unary_operator cast_expression { $$=node(' ', $2, 0); }
	| SIZEOF unary_expression { $$=node(SIZEOF, $2, 0); }
	| SIZEOF '(' type_name ')' { $$=node(SIZEOF, $2, 0); }
	;

unary_operator
	: '&'
	| '*'
	| '+'
	| '-'
	| '~'
	| '!'
	;

cast_expression
	: unary_expression
	| '(' type_name ')' cast_expression { $$=node('(', $2, $4); }
	| '(' type_name ')' '{' struct_component_expression '}'	/* gcc extension to create a temporary struct */
	;

multiplicative_expression
	: cast_expression
	| multiplicative_expression '*' cast_expression { $$=node('*', $1, $3); }
	| multiplicative_expression '/' cast_expression { $$=node('/', $1, $3); }
	| multiplicative_expression '%' cast_expression { $$=node('%', $1, $3); }
	;

additive_expression
	: multiplicative_expression
	| additive_expression '+' multiplicative_expression { $$=node('+', $1, $3); }
	| additive_expression '-' multiplicative_expression { $$=node('-', $1, $3); }
	;

shift_expression
	: additive_expression
	| shift_expression LEFT_OP additive_expression { $$=node(LEFT_OP, $1, $3); }
	| shift_expression RIGHT_OP additive_expression { $$=node(RIGHT_OP, $1, $3); }
	;

relational_expression
	: shift_expression
	| relational_expression '<' shift_expression { $$=node('<', $1, $3); }
	| relational_expression '>' shift_expression { $$=node('>', $1, $3); }
	| relational_expression LE_OP shift_expression { $$=node(LE_OP, $1, $3); }
	| relational_expression GE_OP shift_expression { $$=node(GE_OP, $1, $3); }
	;

equality_expression
	: relational_expression
	| equality_expression EQ_OP relational_expression { $$=node(EQ_OP, $1, $3); }
	| equality_expression NE_OP relational_expression { $$=node(NE_OP, $1, $3); }
	;

and_expression
	: equality_expression
	| and_expression '&' equality_expression { $$=node('&', $1, $3); }
	;

exclusive_or_expression
	: and_expression
	| exclusive_or_expression '^' and_expression { $$=node('^', $1, $3); }
	;

inclusive_or_expression
	: exclusive_or_expression
	| inclusive_or_expression '|' exclusive_or_expression { $$=node('|', $1, $3); }
	;

logical_and_expression
	: inclusive_or_expression
	| logical_and_expression AND_OP inclusive_or_expression { $$=node(AND_OP, $1, $3); }
	;

logical_or_expression
	: logical_and_expression
	| logical_or_expression OR_OP logical_and_expression { $$=node(OR_OP, $1, $3); }
	;

conditional_expression
	: logical_or_expression
	| logical_or_expression '?' expression ':' conditional_expression { $$=node('?', $1, node(':', $3, $5)); }
	;

assignment_expression
	: conditional_expression
	| unary_expression assignment_operator assignment_expression
	;

assignment_operator
	: '='
	| MUL_ASSIGN
	| DIV_ASSIGN
	| MOD_ASSIGN
	| ADD_ASSIGN
	| SUB_ASSIGN
	| LEFT_ASSIGN
	| RIGHT_ASSIGN
	| AND_ASSIGN
	| XOR_ASSIGN
	| OR_ASSIGN
	;

expression
	: assignment_expression
	| expression ',' assignment_expression { $$=node(',', $1, $3); }
	;

constant_expression
	: conditional_expression
	;

class_name_list
	: IDENTIFIER
	| class_name_list ',' IDENTIFIER
	;

class_with_superclass
	: IDENTIFIER
	| IDENTIFIER ':' IDENTIFIER
	;

category_name
	: IDENTIFIER
	;

inherited_protocols
	: protocol_list
	;

class_name_declaration
	: class_with_superclass
	| class_with_superclass '<' inherited_protocols '>'
	| class_with_superclass '(' category_name ')'
	| class_with_superclass '<' inherited_protocols '>' '(' category_name ')'
	;

class_or_instance_method_specifier : '+' | '-' ;

do_atribute_specifier
	: ONEWAY
	| IN
	| OUT
	| INOUT
	| BYREF
	| BYCOPY
	;

objc_declaration_specifiers
	: do_atribute_specifier objc_declaration_specifiers
	| type_name
	;

selector_argument_declaration
	: '(' objc_declaration_specifiers ')' IDENTIFIER
	;

selector_with_argument_declaration
	: IDENTIFIER
	| IDENTIFIER ':' selector_argument_declaration 
	| selector_with_argument_declaration selector_component selector_argument_declaration
	| selector_with_argument_declaration ',' ELLIPSIS
	;

method_declaration
	: class_or_instance_method_specifier '(' objc_declaration_specifiers ')' selector_with_argument_declaration

method_declaration_list
	: method_declaration ';'
	| AT_OPTIONAL method_declaration ';'
	| AT_REQUIRED method_declaration ';'
	| method_declaration_list method_declaration ';'
	;

ivar_declaration_list
	: '{' struct_declaration_list '}'
	;

class_implementation
	: IDENTIFIER
	| IDENTIFIER '(' category_name ')'

method_implementation
	: method_declaration compound_statement
	| method_declaration ';' compound_statement
	;

method_implementation_list
	: method_implementation
	| method_implementation_list method_implementation
	;

objc_declaration
	: AT_CLASS class_name_list ';'
	| AT_PROTOCOL class_name_declaration AT_END
	| AT_PROTOCOL class_name_declaration method_declaration_list AT_END
	| AT_INTERFACE class_name_declaration AT_END
	| AT_INTERFACE class_name_declaration ivar_declaration_list method_declaration_list AT_END
	| AT_INTERFACE class_name_declaration ivar_declaration_list AT_END
	| AT_IMPLEMENTATION class_implementation AT_END
	| AT_IMPLEMENTATION class_implementation ivar_declaration_list AT_END
	| AT_IMPLEMENTATION class_implementation method_implementation_list AT_END
	| AT_IMPLEMENTATION class_implementation ivar_declaration_list method_implementation_list AT_END
	;

declaration
	: declaration_specifiers ';'
	| declaration_specifiers init_declarator_list ';'
	| objc_declaration
	;

declaration_specifiers
	: storage_class_specifier
	| storage_class_specifier declaration_specifiers
	| type_specifier
	| type_specifier declaration_specifiers
	| type_qualifier
	| type_qualifier declaration_specifiers
	;

init_declarator_list
	: init_declarator
	| init_declarator_list ',' init_declarator
	;

init_declarator
	: AT_CLASS IDENTIFIER ';' { /* handle typedef and @class to add symbol to symbol table */ }
	| declarator
	| declarator '=' initializer
	;

storage_class_specifier
	: TYPEDEF
	| EXTERN
	| STATIC
	| AUTO
	| REGISTER
	;

protocol_list
	: IDENTIFIER
	| protocol_list ',' IDENTIFIER

type_specifier
	: VOID
	| CHAR
	| SHORT
	| INT
	| LONG
	| FLOAT
	| DOUBLE
	| SIGNED
	| UNSIGNED
	| struct_or_union_specifier
	| enum_specifier
	| TYPE_NAME
	| ID
	| ID '<' protocol_list '>'
	| SEL
	| BOOL
	| UNICHAR
	| CLASS
	;

struct_or_union_specifier
	: struct_or_union IDENTIFIER '{' struct_declaration_list '}'
	| struct_or_union '{' struct_declaration_list '}'
	| struct_or_union IDENTIFIER
	;

struct_or_union
	: STRUCT
	| UNION
	;

struct_declaration_list
	: struct_declaration
	| struct_declaration_list struct_declaration
	;

property_attributes_list
	: IDENTIFIER
	| IDENTIFIER ',' property_attributes_list
	;

struct_declaration
	: specifier_qualifier_list struct_declarator_list ';'
	| protection_qualifier specifier_qualifier_list struct_declarator_list ';'
	| property_qualifier specifier_qualifier_list struct_declarator_list ';'
	| AT_SYNTHESIZE ivar_list ';'
	;

protection_qualifier
	: AT_PRIVATE
	| AT_PUBLIC
	| AT_PROTECTED
	;

property_qualifier
	: AT_PROPERTY '(' property_attributes_list ')'
	| AT_PROPERTY
	;

ivar_list
	: ivar_list IDENTIFIER
	| IDENTIFIER
	;

specifier_qualifier_list
	: type_specifier specifier_qualifier_list
	| type_specifier
	| type_qualifier specifier_qualifier_list
	| type_qualifier
	;

struct_declarator_list
	: struct_declarator
	| struct_declarator_list ',' struct_declarator
	;

struct_declarator
	: declarator
	| ':' constant_expression
	| declarator ':' constant_expression
	;

enum_specifier
	: ENUM '{' enumerator_list '}'
	| ENUM IDENTIFIER '{' enumerator_list '}'
	| ENUM IDENTIFIER
	;

enumerator_list
	: enumerator
	| enumerator_list ',' enumerator
	;

enumerator
	: IDENTIFIER
	| IDENTIFIER '=' constant_expression
	;

type_qualifier
	: CONST
	| VOLATILE
	| WEAK
	| STRONG
	;

declarator
	: pointer direct_declarator
	| direct_declarator
	;

direct_declarator
	: IDENTIFIER
	| '(' declarator ')'
	| direct_declarator '[' constant_expression ']'
	| direct_declarator '[' ']'
	| direct_declarator '(' parameter_type_list ')'
	| direct_declarator '(' identifier_list ')'
	| direct_declarator '(' ')'
	;

pointer
	: '*'
	| '*' type_qualifier_list
	| '*' pointer
	| '*' type_qualifier_list pointer
	;

type_qualifier_list
	: type_qualifier
	| type_qualifier_list type_qualifier
	;


parameter_type_list
	: parameter_list
	| parameter_list ',' ELLIPSIS  { $$=node(',', $1, node(ELLIPSIS, 0, 0)); }
	;

parameter_list
	: parameter_declaration
	| parameter_list ',' parameter_declaration  { $$=node(',', $1, $3); }
	;

parameter_declaration
	: declaration_specifiers declarator
	| declaration_specifiers abstract_declarator
	| declaration_specifiers
	;

identifier_list
	: IDENTIFIER
	| identifier_list ',' IDENTIFIER  { $$=node(',', $1, $3); }
	;

type_name
	: specifier_qualifier_list
	| specifier_qualifier_list abstract_declarator
	;

abstract_declarator
	: pointer
	| direct_abstract_declarator
	| pointer direct_abstract_declarator
	;

direct_abstract_declarator
	: '(' abstract_declarator ')' { $$ = $2 }
	| '[' ']'  { $$=node('[', 0, 0); }
	| '[' constant_expression ']'  { $$=node('[', $2, 0); }
	| direct_abstract_declarator '[' ']'
	| direct_abstract_declarator '[' constant_expression ']'
	| '(' ')'
	| '(' parameter_type_list ')'
	| direct_abstract_declarator '(' ')'
	| direct_abstract_declarator '(' parameter_type_list ')'
	;

initializer
	: assignment_expression
	| '{' initializer_list '}'
	| '{' initializer_list ',' '}'
	;

initializer_list
	: initializer
	| initializer_list ',' initializer  { $$=node(',', $1, $3); }
	;

statement
	: labeled_statement
	| compound_statement
	| expression_statement
	| selection_statement
	| iteration_statement
	| jump_statement
	| AT_CATCH
	| AT_TRY
	| error ';' 
	| error '}' 
	;

labeled_statement
	: IDENTIFIER ':' statement  { $$=node('$', $1, $3); }
	| CASE constant_expression ':' statement  { $$=node(CASE, $2, $4); }
	| DEFAULT ':' statement  { $$=node(DEFAULT, $3, 0); }
	;

compound_statement
	: '{' '}'  { $$=node('{', 0, 0); }
	| '{' statement_list '}'  { $$=node('{', $2, 0); }
	;

statement_list
	: declaration
	| statement
	| statement_list statement  { $$=node(';', $1, $2); }
	;

expression_statement
	: ';'  { $$=node('e', 0, 0); }
	| expression ';'  { $$=node('e', $1, 0); }
	;

selection_statement
	: IF '(' expression ')' statement
		{
		$$=node(IF, $3, $5);
		}
	| IF '(' expression ')' statement ELSE statement
		{
		$$=node(IF,
				$3,
				node(ELSE, $5, $7)
				);
		}
	| SWITCH '(' expression ')' statement  { $$=node(SWITCH, $3, $5); }
	;

iteration_statement
	: WHILE '(' expression ')' statement  { $$=node(WHILE, $3, $5); }
	| DO statement WHILE '(' expression ')' ';'  { $$=node(DO, $5, $3); }
	| FOR '(' expression_statement expression_statement ')' statement
		{
		$$=node(FOR,
				node(';', $3, $4),
				$6);
		}
	| FOR '(' expression_statement expression_statement expression ')' statement
		{
		$$=node(FOR,
				node(';',
					 $3,
					 node(';', $4, $5)
					 ), 
				$7);
		}
	| FOR '(' declaration expression_statement expression ')' statement	
		{
		$$=node('{',
				$3,
				node(FOR,
					 node(';',
						  0,
						  node(';', $4, $5)
						  ),
					 $7)
				);
		}
	| FOR '(' declaration IN expression ')' statement
		{
			/* emit to { NSEnumerator *e=[expression objectEnumerator]; <type> *obj; while((obj=[e nextObject])) statement } */
		}
	;

jump_statement
	: GOTO IDENTIFIER ';'  { $$=node(GOTO, $2, 0); }
	| CONTINUE ';'  { $$=node(CONTINUE, 0, 0); }
	| BREAK ';' { $$=node(BREAK, 0, 0); }
	| RETURN ';' { $$=node(RETURN, 0, 0); }
	| RETURN expression ';' { $$=node(RETURN, $2, 0); }
	;

external_declaration
	: function_definition
	| declaration
	;

function_definition
	: declaration_specifiers declarator compound_statement { $$=node(' ', node(' ', $1, $2), $3); }
	| declarator compound_statement { $$=node(' ', $1, $2); }
	;

translation_unit
	: external_declaration { printf("#message result\n\n"); emit($1); printf("\n\n"); }
	| translation_unit external_declaration
	;

%%

extern char *yytext;
extern int line, column;

yyerror(s)
char *s;
{
	fflush(stdout);
	printf("#error line %d column %d\n", line, column);
	printf("/* %s\n * %*s\n * %*s\n*/\n", yytext, column, "^", column, s);
	fflush(stdout);
}

struct Node 
{ // internal structure
	int type;
	char *name;
	int left;
	int right;
	int next;
} *nodes;

int nodecount, nodecapacity;

static struct Node *get(int node)
{
	if(node <= 0 || node > nodecount)
		return NULL; // error
	return &nodes[node-1];	// nodes start counting at 1
}

int leaf(int type, const char *name)
{ // create a leaf node
	int n;
	struct Node *node;
	if(nodecount >= nodecapacity)
		{ // (re)alloc
			if(nodecapacity == 0)
				{ // first allocation
					nodecapacity=100;
					nodes=calloc(nodecapacity, sizeof(struct Node));
				}
			else
				{
				nodecapacity=2*nodecapacity+10;	// increase capacity
					nodes=realloc(nodes, nodecapacity*sizeof(struct Node));
				}
		}
	node=&nodes[nodecount++];	// next free node
	node->type=type;
	if(name)
		node->name=strdup(name);
	else
		node->name=NULL;
	node->left=node->right=0;
	node->next=0;
	return nodecount;	// returns node index + 1
}

int node(int type, int left, int right)
{ // create a binary node
	int n=leaf(type, NULL);
	struct Node *node = get(n);
	node->left=left;
	node->right=right;
	return n;
}

int left(int node)
{
	return get(node)->left;
}

int right(int node)
{
	return get(node)->right;
}

int type(int node)
{
	return get(node)->type;
}

void setType(int node, int type)
{
	get(node)->type=type;
}

char *name(int node)
{
	return get(node)->name;
}

int next(int node)
{
	return get(node)->next;
}

void setNext(int node, int next)
{
	get(node)->next=next;
}

int emit(int node)
{ // print tree (as standard C)
	if(node != 0)
		{
			switch(type(node))
			{
				case IDENTIFIER:	printf(" %s", name(node)); break;
				case CONSTANT:	printf(" %s", name(node)); break;
				case ' ':	emit(left(node)); printf(" "); emit(right(node)); break;
				case '{':	printf("{\n"); emit(left(node)); printf("\n}\n"); break;
				case '(':	printf("("); emit(left(node)); printf(")"); break;
				case ';':	emit(left(node)); printf(";\n"); emit(right(node)); break;
				case ',':	emit(left(node)); printf(", "); emit(right(node)); break;
				case '?':	emit(left(node)); printf(" ? "); emit(right(node)); break;
				case ':':	emit(left(node)); printf(" : "); emit(right(node)); break;
				case WHILE:	printf("while ("); emit(left(node)); printf(")\n"); emit(right(node)); printf("\n"); break;
				case DO:	printf("do\n"); emit(left(node)); printf("\nwhile("); emit(right(node)); printf(")\n"); break;
				case IF:	printf("if ("); emit(left(node)); printf("\n"); emit(right(node)); printf("\n"); break;
				case ELSE:	emit(left(node)); printf("\nelse\n"); emit(right(node)); printf("\n"); break;
				default:
					printf("$%d(", type(node));
					emit(left(node));
					printf(", ");
					emit(right(node));
					printf("\n");
					break;
			}
	}

}