/* ObjC-2.0 scanner - based on http://www.lysator.liu.se/c/ANSI-C-grammar-y.html */
/* part of objc2pp - an obj-c 2 preprocessor */

/*
 * FIXME:
 *
 * - accept *any* valid keyword as selector components (and not only non-keywords): + (void) for:x in:y default:z;
 * - correctly handle typedefs for list of names: typedef int t1, t2, t3;
 * - handle nesting of type specifiers, i.e. typedef int (*intfn)(int arg)
 * - handle global/local name scope
 * - handle name spaces for structs and enums
 * - handle @implementation, @interface, @protocol add the object to the (global) symbol table
 * - get notion of 'current class', 'current method' etc.
 * - collect @property entries so that @synthesisze can expand them
 * - add all these Obj-C 2.0 expansions
 *
 */
 
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
%token AT_THROW AT_TRY AT_CATCH AT_FINALLY
%token IN OUT INOUT BYREF BYCOPY ONEWAY

%token AT_PROPERTY AT_SYNTHESIZE AT_OPTIONAL AT_REQUIRED WEAK STRONG

%token IDENTIFIER
%token TYPE_NAME
%token CONSTANT
%token STRING_LITERAL
%token AT_STRING_LITERAL

%start translation_unit

%%

/* FIXME: selectors can consist of *any* word (even if keyword like 'for', 'default') and not only IDENTIFIERs! */

selector_component
	: IDENTIFIER ':'  { $$=node(':', $1, 0); }
	| ':' { $$=node(':', 0, 0); }
	;

selector_with_arguments
	: IDENTIFIER
	| IDENTIFIER ':' expression  { $$=node(':', $1, $3); }
	| selector_with_arguments selector_component expression   { $$=node(' ', $1, node(' ', $2, $3)); }
	| selector_with_arguments ',' ELLIPSIS    { $$=node(',', $1, node(ELLIPSIS, 0, 0)); }
	;

struct_component_expression
	: conditional_expression
	| struct_component_expression conditional_expression   { $$=node(' ', $1, $2); }
	;

selector
	: IDENTIFIER
	| IDENTIFIER ':'  { $$=node(':', $1, 0); }
	| ':'  { $$=node(':', 0, 0); }
	| selector ':'  { $$=node(':', $1, 0); }
	;

primary_expression
	: IDENTIFIER
	| CONSTANT
	| STRING_LITERAL
	| '(' expression ')'  { $$=node('(', 0, $2); }
	/* Obj-C extensions */
	| AT_STRING_LITERAL
	| AT_SELECTOR '(' selector ')'  { $$=node('(', node(AT_SELECTOR, 0, 0), $3); }
	| AT_ENCODE '(' type_name ')'  { $$=node('(', node(AT_ENCODE, 0, 0), $3); }
	| AT_PROTOCOL '(' IDENTIFIER ')'  { $$=node('(', node(AT_PROTOCOL, 0, 0), $3); }
	| '[' expression selector_with_arguments ']'  { $$=node('[', 0, node(' ', $2, $3)); }
	;

postfix_expression
	: primary_expression
	| postfix_expression '[' expression ']'  { $$=node('[', $1, $3); }
	| postfix_expression '(' ')'  { $$=node('(', $1, 0); }
	| postfix_expression '(' argument_expression_list ')'  { $$=node('(', $1, $3); }
	| postfix_expression '.' IDENTIFIER
		{
		/* if expression is object, replace by [object valueForKey:@"path.path."] - or setValue if we are part of an LValue */
		$$=node('.', $1, $3);
		}
	| postfix_expression PTR_OP IDENTIFIER  { $$=node(PTR_OP, $1, 0); }
	| postfix_expression INC_OP  { $$=node(INC_OP, $1, 0); }
	| postfix_expression DEC_OP  { $$=node(DEC_OP, $1, 0); }
	;

argument_expression_list
	: assignment_expression
	| argument_expression_list ',' assignment_expression  { $$=node(',', $1, $3); }
	;

unary_expression
	: postfix_expression
// FIXME: is ++(char *) x really invalid?
	| INC_OP unary_expression { $$=node(INC_OP, 0, $2); }
	| DEC_OP unary_expression { $$=node(DEC_OP, 0, $2); }
	| unary_operator cast_expression { $$=node(type($1), 0, $2); dealloc($1); }
	| SIZEOF unary_expression { $$=node(SIZEOF, 0, $2); }
	| SIZEOF '(' type_name ')' { $$=node(SIZEOF, 0, $2); }
	;

unary_operator
	: '&'  { $$=node('&', 0, 0); }
	| '*'  { $$=node('*', 0, 0); }
	| '+'  { $$=node('+', 0, 0); }
	| '-'  { $$=node('-', 0, 0); }
	| '~'  { $$=node('~', 0, 0); }
	| '!'  { $$=node('!', 0, 0); }
	;

cast_expression
	: unary_expression
	| '(' type_name ')' cast_expression { $$=node(' ', node('(', 0, $2), $4); }
	| '(' type_name ')' '{' struct_component_expression '}'	 { $$=node('{', node('(', 0, $2), $4); }
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
	| unary_expression '.' IDENTIFIER assignment_operator assignment_expression /* check for calling Obj-C 2 setters */
	| unary_expression assignment_operator assignment_expression  { $$=node(type($2), $1, $3); dealloc($2); }
	;

assignment_operator
	: '='   { $$=node('=', 0, 0); }
	| MUL_ASSIGN   { $$=node(MUL_ASSIGN, 0, 0); }
	| DIV_ASSIGN   { $$=node(DIV_ASSIGN, 0, 0); }
	| MOD_ASSIGN   { $$=node(MOD_ASSIGN, 0, 0); }
	| ADD_ASSIGN   { $$=node(ADD_ASSIGN, 0, 0); }
	| SUB_ASSIGN   { $$=node(SUB_ASSIGN, 0, 0); }
	| LEFT_ASSIGN   { $$=node(LEFT_ASSIGN, 0, 0); }
	| RIGHT_ASSIGN   { $$=node(RIGHT_ASSIGN, 0, 0); }
	| AND_ASSIGN   { $$=node(AND_ASSIGN, 0, 0); }
	| XOR_ASSIGN   { $$=node(XOR_ASSIGN, 0, 0); }
	| OR_ASSIGN   { $$=node(OR_ASSIGN, 0, 0); }
	;

expression
	: assignment_expression
	| expression ',' assignment_expression  { $$=node(',', $1, $3); }
	;

constant_expression
	: conditional_expression
	;

class_name_list
	: IDENTIFIER
	| class_name_list ',' IDENTIFIER  { $$=node(',', $1, $3); }
	;

class_with_superclass
	: IDENTIFIER
	| IDENTIFIER ':' IDENTIFIER  { $$=node(':', $1, $3); }
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
	| class_with_superclass '(' category_name ')'  { $$=node('(', $1, $3); }
	| class_with_superclass '<' inherited_protocols '>' '(' category_name ')'  { $$=node(',', $1, $5); }
	| error
	;

class_or_instance_method_specifier
	: '+'  { $$=node('+', 0, 0); }
	| '-'  { $$=node('-', 0, 0); }
	;

/* FIXME - there are valid combinations i.e. byref out! */

do_atribute_specifier
	: ONEWAY  { $$=node(ONEWAY, 0, 0); }
	| IN  { $$=node(IN, 0, 0); }
	| OUT  { $$=node(OUT, 0, 0); }
	| INOUT  { $$=node(INOUT, 0, 0); }
	| BYREF  { $$=node(BYREF, 0, 0); }
	| BYCOPY  { $$=node(BYCOPY, 0, 0); }
	;

objc_declaration_specifiers
	: do_atribute_specifier objc_declaration_specifiers  { $$=node(' ', $1, $2); }
	| type_name
	;

selector_argument_declaration
	: '(' objc_declaration_specifiers ')' IDENTIFIER  { $$=node(' ', node('(', 0, $2), $4); }
	;

selector_with_argument_declaration
	: IDENTIFIER
	| IDENTIFIER ':' selector_argument_declaration   { $$=node(':', $1, $3); }
	| selector_with_argument_declaration selector_component selector_argument_declaration  { $$=node(' ', $1, node(' ', $2, $3)); }
	| selector_with_argument_declaration ',' ELLIPSIS  { $$=node(',', $1, node(ELLIPSIS, 0, 0)); }
	;

method_declaration
	: class_or_instance_method_specifier '(' objc_declaration_specifiers ')' selector_with_argument_declaration
		{
		$$=node(type($1),
				0,
				node(' ',
					 node('(', 0, $3),
					 $5
					 )
				);
		dealloc($1);
		}
	;

method_declaration_list
	: method_declaration ';'  { $$=node(';', $1, 0); }
	| AT_OPTIONAL method_declaration ';'  { $$=node(';', $1, 0); }
	| AT_REQUIRED method_declaration ';'  { $$=node(';', $1, 0); }
	| method_declaration_list method_declaration ';'  { $$=node(' ', $1, node(';', $2, 0)); }
	| error ';'
	;

ivar_declaration_list
	: '{' struct_declaration_list '}'  { $$=node('{', 0, $2); }
	;

class_implementation
	: IDENTIFIER
	| IDENTIFIER '(' category_name ')'  { $$=node('(', $1, $3); }

method_implementation
	: method_declaration compound_statement  { $$=node(' ', $1, $2); }
	| method_declaration ';' compound_statement  { $$=node(' ', $1, $3); }	/* ignore extra ; */
	;

method_implementation_list
	: method_implementation
	| method_implementation_list method_implementation  { $$=node(' ', $1, $2); }
	;

objc_declaration
	: AT_CLASS class_name_list ';'
		{
		$$=node(';',
				node(AT_CLASS, 0, $2),
				0);
		/* FIXME: do for all class names in the list! */
		setRight($2, $$);	/* this makes it a TYPE_NAME since $2 is the symbol table entry */
		}
	| AT_PROTOCOL class_name_declaration AT_END  { $$=node(AT_PROTOCOL, $2, 0); }
	| AT_PROTOCOL class_name_declaration method_declaration_list AT_END  { $$=node(AT_PROTOCOL, $2, $3); }
	| AT_INTERFACE class_name_declaration AT_END  { $$=node(AT_INTERFACE, $2, 0); }
	| AT_INTERFACE class_name_declaration ivar_declaration_list AT_END  { $$=node(AT_INTERFACE, $2, node(' ', $3, 0)); }
	| AT_INTERFACE class_name_declaration ivar_declaration_list method_declaration_list AT_END  { $$=node(AT_INTERFACE, $2, node(' ', $3, $4)); }
	| AT_IMPLEMENTATION class_implementation AT_END  { $$=node(AT_IMPLEMENTATION, $2, 0); }
	| AT_IMPLEMENTATION class_implementation ivar_declaration_list AT_END  { $$=node(AT_IMPLEMENTATION, $2, node(' ', $3, 0)); }
	| AT_IMPLEMENTATION class_implementation method_implementation_list AT_END  { $$=node(AT_IMPLEMENTATION, $2, node(' ', 0, $3)); }
	| AT_IMPLEMENTATION class_implementation ivar_declaration_list method_implementation_list AT_END  { $$=node(AT_IMPLEMENTATION, $2, node(' ', $3, $4)); }
	;

declaration
	: declaration_specifiers ';'  { $$=node(';', $1, 0); }
	| declaration_specifiers init_declarator_list ';'  { $$=node(';', node(' ', $1, $2), 0); }
	| objc_declaration
	;

declaration_specifiers
	: storage_class_specifier
	| storage_class_specifier declaration_specifiers
		{
		if($1 == TYPEDEF)
			{
			setRight($2, $$);	/* make it a TYPE_NAME */
			$$=node(' ', 0, 0);	/* eat all typedef declarations since we expand them */
			}
		else
			{
			$$=node(' ', $1, $2);
			}
		}
	| type_specifier
	| type_specifier declaration_specifiers  { $$=node(' ', $1, 0); }
	| type_qualifier
	| type_qualifier declaration_specifiers  { $$=node(' ', $1, 0); }
	;

init_declarator_list
	: init_declarator
	| init_declarator_list ',' init_declarator  { $$=node(',', $1, $3); }
	;

init_declarator
	: declarator
	| declarator '=' initializer  { $$=node('=', $1, $3); }
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
	| protocol_list ',' IDENTIFIER  { $$=node(',', $1, $3); }

type_specifier
	: VOID	{ $$=node(VOID, 0, 0); }
	| CHAR	{ $$=node(CHAR, 0, 0); }
	| SHORT	{ $$=node(SHORT, 0, 0); }
	| INT	{ $$=node(INT, 0, 0); }
	| LONG	{ $$=node(LONG, 0, 0); }
	| FLOAT	{ $$=node(FLOAT, 0, 0); }
	| DOUBLE	{ $$=node(DOUBLE, 0, 0); }
	| SIGNED	{ $$=node(SIGNED, 0, 0); }
	| UNSIGNED	{ $$=node(UNSIGNED, 0, 0); }
	| struct_or_union_specifier
	| enum_specifier
	| TYPE_NAME		{ $$=right($1); }
	| ID	{ $$=node(ID, 0, 0); }
	| ID '<' protocol_list '>'	{ $$=node(ID, 0, $3); }
	| SEL	{ $$=node(SEL, 0, 0); }
	| BOOL	{ $$=node(BOOL, 0, 0); }
	| UNICHAR	{ $$=node(UNICHAR, 0, 0); }
	| CLASS	{ $$=node(CLASS, 0, 0); }
	;

struct_or_union_specifier
	: struct_or_union IDENTIFIER '{' struct_declaration_list '}'  { $$=node(type($1), $2, $3); setRight($2, $$); dealloc($1); }
	| struct_or_union '{' struct_declaration_list '}'  { $$=node(type($1), 0, $3); dealloc($1); }
	| struct_or_union IDENTIFIER  { $$=node(type($1), $2, 0); setRight($2, $$); dealloc($1);}
	;

struct_or_union
	: STRUCT	{ $$=node(STRUCT, 0, 0); }
	| UNION		{ $$=node(UNION, 0, 0); }
	;

struct_declaration_list
	: struct_declaration
	| struct_declaration_list struct_declaration  { $$=node(' ', $1, $2); }
	;

property_attributes_list
	: IDENTIFIER
	| IDENTIFIER ',' property_attributes_list  { $$=node(',', $1, $3); }
	;

struct_declaration
	: specifier_qualifier_list struct_declarator_list ';'  { $$=node(';', node(' ', $1, $2), 0); }
	| protection_qualifier specifier_qualifier_list struct_declarator_list ';'  { $$=node(';', node(' ', node(' ', $1, $2), $3), 0); }
	| property_qualifier specifier_qualifier_list struct_declarator_list ';'  { $$=node(';', node(' ', node(' ', $1, $2), $3), 0); }
	| AT_SYNTHESIZE ivar_list ';'  { $$=node(AT_SYNTHESIZE, $2, 0); }
	| AT_DEFS '(' IDENTIFIER ')' { ; }	// substitute the iVar definition tree
	;

protection_qualifier
	: AT_PRIVATE
	| AT_PUBLIC
	| AT_PROTECTED
	;

property_qualifier
	: AT_PROPERTY '(' property_attributes_list ')'  { $$=node('(', $1, $3); }
	| AT_PROPERTY
	;

ivar_list
	: ivar_list IDENTIFIER  { $$=node(' ', $1, $2); }
	| IDENTIFIER
	;

specifier_qualifier_list
	: type_specifier specifier_qualifier_list  { $$=node(' ', $1, $2); }
	| type_specifier
	| type_qualifier specifier_qualifier_list  { $$=node(' ', $1, $2); }
	| type_qualifier
	;

struct_declarator_list
	: struct_declarator
	| struct_declarator_list ',' struct_declarator  { $$=node(',', $1, $3); }
	;

struct_declarator
	: declarator
	| ':' constant_expression  { $$=node(':', 0, $2); }
	| declarator ':' constant_expression  { $$=node(':', $1, $3); }
	;

enum_specifier
	: ENUM '{' enumerator_list '}'
	| ENUM IDENTIFIER '{' enumerator_list '}'
	| ENUM IDENTIFIER
	;

enumerator_list
	: enumerator
	| enumerator_list ',' enumerator  { $$=node(',', $1, $3); }
	;

enumerator
	: IDENTIFIER
	| IDENTIFIER '=' constant_expression  { $$=node('=', $1, $3); }
	;

type_qualifier
	: CONST
	| VOLATILE
	| WEAK
	| STRONG
	;

declarator
	: pointer direct_declarator  { $$=node(' ', $1, $2); }
	| direct_declarator
	;

direct_declarator
	: IDENTIFIER
	| '(' declarator ')'  { $$=node('(', 0, $2); }
	| direct_declarator '[' constant_expression ']'  { $$=node('[', $1, $3); }
	| direct_declarator '[' ']'  { $$=node('[', $1, 0); }
	| direct_declarator '(' parameter_type_list ')'  { $$=node('(', $1, $3); }
	| direct_declarator '(' identifier_list ')'  { $$=node('(', $1, $3); }
	| direct_declarator '(' ')'  { $$=node('(', $1, 0); }
	;

pointer
	: '*'  { $$=node('*', 0, 0); }
	| '*' type_qualifier_list  { $$=node('*', 0, $2); }
	| '*' pointer  { $$=node('*', 0, $2); }
	| '*' type_qualifier_list pointer  { $$=node('*', $2, $3); }
	;

type_qualifier_list
	: type_qualifier
	| type_qualifier_list type_qualifier  { $$=node(' ', $1, $2); }
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
	: declaration_specifiers declarator  { $$=node(' ', $1, $2); }
	| declaration_specifiers abstract_declarator  { $$=node(' ', $1, $2); }
	| declaration_specifiers
	;

identifier_list
	: IDENTIFIER
	| identifier_list ',' IDENTIFIER  { $$=node(',', $1, $3); }
	;

type_name
	: specifier_qualifier_list
	| specifier_qualifier_list abstract_declarator  { $$=node(' ', $1, $2); }
	;

abstract_declarator
	: pointer
	| direct_abstract_declarator
	| pointer direct_abstract_declarator  { $$=node(' ', $1, $2); }
	;

direct_abstract_declarator
	: '(' abstract_declarator ')' { $$=node('(', 0, $2); }
	| '[' ']'  { $$=node('[', 0, 0); }
	| '[' constant_expression ']'  { $$=node('[', 0, $2); }
	| direct_abstract_declarator '[' ']'  { $$=node('[', $1, 0); }
	| direct_abstract_declarator '[' constant_expression ']'  { $$=node('[', $1, $2); }
	| '(' ')'  { $$=node('(', 0, 0); }
	| '(' parameter_type_list ')'  { $$=node('(', 0, $2); }
	| direct_abstract_declarator '(' ')'  { $$=node('(', $1, 0); }
	| direct_abstract_declarator '(' parameter_type_list ')'  { $$=node('(', $1, $2); }
	;

initializer
	: assignment_expression
	| '{' initializer_list '}'  { $$=node('{', 0, $2); }
	| '{' initializer_list ',' '}'  { $$=node('{', 0, $2); }	/* removes extra , */
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
	| AT_TRY compound_statement catch_sequence finally
	| AT_THROW ';'	// rethrow within @catch block
	| AT_THROW expression ';'
	| error ';' 
	| error '}'
	;

catch_sequence
	: AT_CATCH compound_statement{ $$=node(AT_CATCH, 0, 0); }
	| catch_sequence AT_CATCH compound_statement{ $$=node(AT_CATCH, 0, 0); }
	;

finally
	: AT_FINALLY compound_statement
	;

labeled_statement
	: IDENTIFIER ':' statement  { $$=node(':', $1, $3); }
	| CASE constant_expression ':' statement  { $$=node(CASE, $2, $4); }
	| DEFAULT ':' statement  { $$=node(DEFAULT, 0, $3); }
	;

compound_statement
	: '{' '}'  { $$=node('{', 0, 0); }
	| '{' statement_list '}'  { $$=node('{', 0, $2); }
	;

statement_list
	: declaration
	| statement
	| statement_list statement  { $$=node(' ', $1, $2); }
	;

expression_statement
	: ';'  { $$=node(';', 0, 0); }
	| expression ';'  { $$=node(';', $1, 0); }
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
	: GOTO IDENTIFIER ';'  { $$=node(';', node(GOTO, 0, $2), 0); }
	| CONTINUE ';'  { $$=node(';', node(CONTINUE, 0, 0), 0); }
	| BREAK ';' { $$=node(';', node(BREAK, 0, 0), 0); }
	| RETURN ';' { $$=node(';', node(RETURN, 0, 0), 0); }
	| RETURN expression ';' { $$=node(';', node(RETURN, 0, $2), 0); }
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
	: external_declaration { printf("#message result\n\n"); emit($1); printf("\n\n"); dealloc($1); }
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

char *indent(int level)
{
	static char indent[]="                                               ";
	level = sizeof(indent)-1 - 4*level;	
	if(level < 0)
		level=0;
	return &indent[level];	
}

#define STYLE1

int emit(int node)
{ /* print tree (as standard C) */
	static int level=0;
	if(node != 0)
		{
			int t=type(node);
			switch(t)
			{
				case IDENTIFIER:	printf("%s", name(node)); break;
				case CONSTANT:	printf("%s", name(node)); break;
				case ' ':	emit(left(node)); if(left(node) || right(node)) printf(" "); emit(right(node)); break;
#ifdef STYLE1
				case '{':	emit(left(node)); if(right(node)) { printf(" {\n%s", indent(++level)); emit(right(node)); printf("\n%s}\n", indent(level--)); } break;
#else
				case '{':	emit(left(node)); if(right(node)) { level++; printf("\n%s{\n%s", indent(level), indent(level)); emit(right(node)); printf("\n%s}\n", indent(level)); level--; } break;
#endif
				case '(':	emit(left(node)); printf("("); emit(right(node)); printf(")"); break;
				case '[':	emit(left(node)); printf("["); emit(right(node)); printf("]"); break;
				case ':':	emit(left(node)); printf(":"); emit(right(node)); break;
				case ';':	emit(left(node)); printf(";\n%s", indent(level)); emit(right(node)); break;
				case ',':	emit(left(node)); if(right(node)) printf(", "); emit(right(node)); break;
				case '?':	emit(left(node)); printf(" ? "); emit(right(node)); break;
				case WHILE:	printf("while ("); emit(left(node)); printf(")\n%s", indent(++level)); emit(right(node)); printf("\n%s", indent(--level)); break;
				case DO:	printf("do\n%s", indent(++level)); emit(left(node)); printf("\nwhile("); emit(right(node)); printf(")\n%s", indent(--level)); break;
				case IF:	printf("if ("); emit(left(node)); printf("\n%s", indent(++level)); emit(right(node)); printf("\n%s", indent(--level)); break;
				case ELSE:	emit(left(node)); printf("\nelse\n"); emit(right(node)); printf("\n"); break;
				default:
				{
					char *w=keyword(0, t);	/* try to translate type into keyword */
					if(w)
						{
						emit(left(node));
#ifdef STYLE1
						printf(" %s ", w);
#else
						printf("%s", w);
#endif
						emit(right(node));
						}
					else if(t >= ' ' && t <= '~')
						{ // standard single character operator
						emit(left(node));
#ifdef STYLE1
						printf(" %c ", t);
#else
						printf("%c", t);
#endif
						emit(right(node));
						}
					else
						{
						printf("$%d(", t);
						emit(left(node));
						if(left(node) && right(node))
							printf(", ");
						emit(right(node));
						printf(")\n");
						}
					break;
				}
			}
	}

}