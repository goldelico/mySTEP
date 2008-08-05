/* ObjC-2.0 scanner - based on http://www.lysator.liu.se/c/ANSI-C-grammar-y.html */

%token SIZEOF PTR_OP INC_OP DEC_OP LEFT_OP RIGHT_OP LE_OP GE_OP EQ_OP NE_OP
%token AND_OP OR_OP MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN
%token SUB_ASSIGN LEFT_ASSIGN RIGHT_ASSIGN AND_ASSIGN
%token XOR_ASSIGN OR_ASSIGN TYPE_NAME

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

%start translation_unit

%union
{
	char *string;
}

%token <string> IDENTIFIER
%token <string> CONSTANT
%token <string> STRING_LITERAL
%token <string> AT_STRING_LITERAL

%%

// define result type for each expansion

// how can we do that for all to return a <string>?

%type <string> selector_component selector_with_arguments

selector_component
	: IDENTIFIER ':' { $$ = strdupcat($1, ":"); }
	| ':' { $$ = ":"; }
	;

selector_with_arguments
	: IDENTIFIER { $$ = $1; }
	| IDENTIFIER ':' expression  { $$ = strdupcat3($1, ":", $3); }
	| selector_with_arguments selector_component expression { $$ = strdupcat($1, $2, $3); }
	| selector_with_arguments ',' ELLIPSIS  { $$ = strdupcat($1, ", ..."); }
	;

struct_component_expression
	: conditional_expression
	| struct_component_expression conditional_expression
	;

selector
	: IDENTIFIER
	| ':' { $$ = ":"; }
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
	| INC_OP unary_expression
	| DEC_OP unary_expression
	| unary_operator cast_expression
	| SIZEOF unary_expression
	| SIZEOF '(' type_name ')'
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
	| '(' type_name ')' cast_expression
	| '(' type_name ')' '{' struct_component_expression '}'	/* gcc extension to create a temporary struct */
	;

multiplicative_expression
	: cast_expression
	| multiplicative_expression '*' cast_expression
	| multiplicative_expression '/' cast_expression
	| multiplicative_expression '%' cast_expression
	;

additive_expression
	: multiplicative_expression
	| additive_expression '+' multiplicative_expression
	| additive_expression '-' multiplicative_expression
	;

shift_expression
	: additive_expression
	| shift_expression LEFT_OP additive_expression
	| shift_expression RIGHT_OP additive_expression
	;

relational_expression
	: shift_expression
	| relational_expression '<' shift_expression
	| relational_expression '>' shift_expression
	| relational_expression LE_OP shift_expression
	| relational_expression GE_OP shift_expression
	;

equality_expression
	: relational_expression
	| equality_expression EQ_OP relational_expression
	| equality_expression NE_OP relational_expression
	;

and_expression
	: equality_expression
	| and_expression '&' equality_expression
	;

exclusive_or_expression
	: and_expression
	| exclusive_or_expression '^' and_expression
	;

inclusive_or_expression
	: exclusive_or_expression
	| inclusive_or_expression '|' exclusive_or_expression
	;

logical_and_expression
	: inclusive_or_expression
	| logical_and_expression AND_OP inclusive_or_expression
	;

logical_or_expression
	: logical_and_expression
	| logical_or_expression OR_OP logical_and_expression
	;

conditional_expression
	: logical_or_expression
	| logical_or_expression '?' expression ':' conditional_expression
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
	| expression ',' assignment_expression
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
	: declarator { /* handle typedef and @class to add symbol to symbol table */ }
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
	| AT_PRIVATE specifier_qualifier_list struct_declarator_list ';'
	| AT_PUBLIC specifier_qualifier_list struct_declarator_list ';'
	| AT_PROTECTED specifier_qualifier_list struct_declarator_list ';'
	| AT_PROPERTY '(' property_attributes_list ')' specifier_qualifier_list struct_declarator_list ';'
	| AT_PROPERTY specifier_qualifier_list struct_declarator_list ';'
	| AT_SYNTHESIZE ivar_list ';'
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
	| parameter_list ',' ELLIPSIS
	;

parameter_list
	: parameter_declaration
	| parameter_list ',' parameter_declaration
	;

parameter_declaration
	: declaration_specifiers declarator
	| declaration_specifiers abstract_declarator
	| declaration_specifiers
	;

identifier_list
	: IDENTIFIER
	| identifier_list ',' IDENTIFIER
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
	: '(' abstract_declarator ')'
	| '[' ']'
	| '[' constant_expression ']'
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
	| initializer_list ',' initializer
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
	;

labeled_statement
	: IDENTIFIER ':' statement
	| CASE constant_expression ':' statement
	| DEFAULT ':' statement
	;

compound_statement
	: '{' '}'
	| '{' statement_list '}'
	| '{' declaration_list '}'
	| '{' declaration_list statement_list '}'
/* add embedded declarations and tranlate to { declaration_list statement_list } */
	;

declaration_list
	: declaration
	| declaration_list declaration
	;

statement_list
	: statement
	| statement_list statement
	;

expression_statement
	: ';'
	| expression ';'
	;

selection_statement
	: IF '(' expression ')' statement
	| IF '(' expression ')' statement ELSE statement
	| SWITCH '(' expression ')' statement
	;

iteration_statement
	: WHILE '(' expression ')' statement
	| DO statement WHILE '(' expression ')' ';'
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
	: GOTO IDENTIFIER ';'
	| CONTINUE ';'
	| BREAK ';'
	| RETURN ';'
	| RETURN expression ';'
	;

translation_unit
	: external_declaration
	| translation_unit external_declaration
	;

external_declaration
	: function_definition
	| declaration
	;

function_definition
	: declaration_specifiers declarator declaration_list compound_statement
	| declaration_specifiers declarator compound_statement
	| declarator declaration_list compound_statement
	| declarator compound_statement
	;

%%
#include <stdio.h>

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