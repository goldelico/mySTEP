//
//  Printing.m
//  objc2pp
//
//  Created by H. Nikolaus Schaller on 16.02.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "Printing.h"
#include "y.tab.h"


@implementation Node (Printing)

- (void) print:(int) level;
{
	int t=[self type];
	switch(t)
	{
		case IDENTIFIER:	printf("%s", [self name]); break;
		case CONSTANT:	printf("%s", [self name]); break;
		case ' ':	[[self left] print:level+1];
					if([self left] || [self right])
						printf(" ");
					[[self right] print:level+1];
						break;
#if OLDCODE
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
#endif
	}
}

- (void) print;
{
	[self print:0];
}

@end
