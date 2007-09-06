

main()
{
	extern int yyparse();
	extern int yydebug;
	yydebug=1;
	return(yyparse());
}

