/* ObjC-2.0 scanner - based on http://www.lysator.liu.se/c/ANSI-C-grammar-y.html */
/* part of ocpp - an obj-c preprocessor */

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
	| INC_OP unary_expression { $$=node1(INC_OP, $2); }
	| DEC_OP unary_expression { $$=node1(DEC_OP, $2); }
	| unary_operator cast_expression
	| SIZEOF unary_expression { $$=node1(SIZEOF, $2); }
	| SIZEOF '(' type_name ')' { $$=node1(SIZEOF, $2); }
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
	| '(' type_name ')' cast_expression { $$=node1('(', $2, $4); }
	| '(' type_name ')' '{' struct_component_expression '}'	/* gcc extension to create a temporary struct */
	;

multiplicative_expression
	: cast_expression
	| multiplicative_expression '*' cast_expression { $$=node1('*', $1, $3); }
	| multiplicative_expression '/' cast_expression { $$=node1('/', $1, $3); }
	| multiplicative_expression '%' cast_expression { $$=node1('%', $1, $3); }
	;

additive_expression
	: multiplicative_expression
	| additive_expression '+' multiplicative_expression { $$=node1('+', $1, $3); }
	| additive_expression '-' multiplicative_expression { $$=node1('-', $1, $3); }
	;

shift_expression
	: additive_expression
	| shift_expression LEFT_OP additive_expression { $$=node1(LEFT_OP, $1, $3); }
	| shift_expression RIGHT_OP additive_expression { $$=node1(RIGHT_OP, $1, $3); }
	;

relational_expression
	: shift_expression
	| relational_expression '<' shift_expression { $$=node1('<', $1, $3); }
	| relational_expression '>' shift_expression { $$=node1('>', $1, $3); }
	| relational_expression LE_OP shift_expression { $$=node1(LE_OP, $1, $3); }
	| relational_expression GE_OP shift_expression { $$=node1(GE_OP, $1, $3); }
	;

equality_expression
	: relational_expression
	| equality_expression EQ_OP relational_expression { $$=node1(EQ_OP, $1, $3); }
	| equality_expression NE_OP relational_expression { $$=node1(NE_OP, $1, $3); }
	;

and_expression
	: equality_expression
	| and_expression '&' equality_expression { $$=node1('&', $1, $3); }
	;

exclusive_or_expression
	: and_expression
	| exclusive_or_expression '^' and_expression { $$=node1('^', $1, $3); }
	;

inclusive_or_expression
	: exclusive_or_expression
	| inclusive_or_expression '|' exclusive_or_expression { $$=node1('|', $1, $3); }
	;

logical_and_expression
	: inclusive_or_expression
	| logical_and_expression AND_OP inclusive_or_expression { $$=node1(AND_OP, $1, $3); }
	;

logical_or_expression
	: logical_and_expression
	| logical_or_expression OR_OP logical_and_expression { $$=node1(OR_OP, $1, $3); }
	;

conditional_expression
	: logical_or_expression
	| logical_or_expression '?' expression ':' conditional_expression { $$=node1('?', $1, node1(':', $3, $5)); }
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
	| expression ',' assignment_expression { $$=node1(',', $1, $3); }
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
	| parameter_list ',' ELLIPSIS  { $$=node1(',', $1, node1(ELLIPSIS, NULL, NULL)); }
	;

parameter_list
	: parameter_declaration
	| parameter_list ',' parameter_declaration  { $$=node1(',', $1, $3); }
	;

parameter_declaration
	: declaration_specifiers declarator
	| declaration_specifiers abstract_declarator
	| declaration_specifiers
	;

identifier_list
	: IDENTIFIER
	| identifier_list ',' IDENTIFIER  { $$=node1(',', $1, $3); }
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
	| '[' ']'  { $$=node1('[', NULL, NULL); }
	| '[' constant_expression ']'  { $$=node1('[', $2); }
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
	| initializer_list ',' initializer  { $$=node1(',', $1, $3); }
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
	: IDENTIFIER ':' statement  { $$=node1('$', $1, $3); }
	| CASE constant_expression ':' statement  { $$=node1(CASE, $2, $4); }
	| DEFAULT ':' statement  { $$=node1(DEFAULT, $3, NULL); }
	;

compound_statement
	: '{' '}'  { $$=node1('{', NULL, NULL); }
	| '{' statement_list '}'  { $$=node1('{', $2, NULL); }
	;

statement_list
	: declaration
	| statement
	| statement_list statement  { $$=node1(';', $1, $2); }
	;

expression_statement
	: ';'  { $$=node1('e', NULL, NULL); }
	| expression ';'  { $$=node1('e', $1, NULL); }
	;

selection_statement
	: IF '(' expression ')' statement  { $$=node1(IF, $3, $5); }
	| IF '(' expression ')' statement ELSE statement  { $$=node1(IF, $3, node1(ELSE, $5, $7)); }
	| SWITCH '(' expression ')' statement  { $$=node1(SWITCH, $3, $5); }
	;

iteration_statement
	: WHILE '(' expression ')' statement  { $$=node1(WHILE, $3, $5); }
	| DO statement WHILE '(' expression ')' ';'  { $$=node1(DO, $5, $3); }
	| FOR '(' expression_statement expression_statement ')' statement
	| FOR '(' expression_statement expression_statement expression ')' statement
		{
		/* $$=print("for(%s; %s; %s) %s", $3, $4, $5, $7) */
		}
	| FOR '(' declaration expression_statement expression ')' statement	
		{
		/* translate to { declaration; for(; statement; statement) statement } */
		}
	| FOR '(' declaration IN expression ')' statement
		{
		/* translate to { NSEnumerator *e=[array objectEnumerator]; while((obj=[e nextObject])) statement } */
		}
	;

jump_statement
	: GOTO IDENTIFIER ';'  { $$=node1(GOTO, $2, NULL); }
	| CONTINUE ';'  { $$=node1(CONTINUE, NULL, NULL); }
	| BREAK ';' { $$=node1(BREAK, NULL, NULL); }
	| RETURN ';' { $$=node1(RETURN, NULL, NULL); }
	| RETURN expression ';' { $$=node1(RETURN, $2, NULL); }
	;

external_declaration
	: function_definition
	| declaration
	;

function_definition
	: declaration_specifiers declarator compound_statement
	| declarator compound_statement
	;

translation_unit
	: external_declaration { translate((struct Node *) $1); }
	| translation_unit external_declaration
	;

%%
#include <stdio.h>
#include <string.h>

#include "node.h"

extern char *yytext;
extern int line, column;

yyerror(s)
char *s;
{
	fflush(stdout);
	printf("line %d column %d\n", line, column);
	printf("%s\n%*s\n%*s\n", yytext, column, "^", column, s);
	fflush(stdout);
}

int node(int type, const char *name)
{ // create a node
	struct Node *n=malloc(sizeof(struct Node));
	n->type=type;
	n->name=strdup(name);
	n->left=n->right=NULL;
	n->next=NULL;
	return (int) n;
}

int node1(int type, int left, int right)
{ // create a node
	struct Node *n=(struct Node *) node(type, NULL);
	n->left=(struct Node *) left;
	n->right=(struct Node *) right;
	return (int) n;
}

int translate(struct Node *n)
{
	if(n != 0)
		{
			switch(n->type)
			{
				case IDENTIFIER:	printf(" %s", n->name); break;
				case CONSTANT:	printf(" %s", n->name); break;
				case '{':	printf("{"); translate(n->left); printf("}\n"); break;
				case '(':	printf("("); translate(n->left); printf(")"); break;
				case ';':	translate(n->left); printf(";\n"); translate(n->right); break;
				case ',':	translate(n->left); printf(", "); translate(n->right); break;
				case '?':	translate(n->left); printf(" ? "); translate(n->right); break;
				case ':':	translate(n->left); printf(" : "); translate(n->right); break;
				case IF:	printf("if ("); translate(n->left); printf("\n"); translate(n->right); printf("\n"); break;
				case ELSE:	translate(n->left); printf("\nelse\n"); translate(n->right); printf("\n"); break;
			}
	}

}