/*
 Application: PDFCombine
 Copyright (C) 2005  Michael Bianco <software@mabwebdesign.com>
 
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */


#import <Foundation/Foundation.h>
#import <Quartz/Quartz.h>

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	NSArray *arguments = [[NSProcessInfo processInfo] arguments];
	//NSLog(@"arguments: %@", arguments);
	
	if([arguments count] == 1 ||
	   [[arguments objectAtIndex:1] isEqualToString:@"-help"] || 
	   [[arguments objectAtIndex:1] isEqualToString:@"--help"]) {//then display a help message
		printf(
			  "PDFCombine is a command line ultility that allows you to combine the pages from multiple PDF files into one singular PDF file.\n"
			  "Usage:\n\npdfcombine inputpdf1.pdf inputpdf2.pdf ... -o output.pdf\n\n"
			  "Copywrite 2005 Michael Bianco, http://developer.mabwebdesign.com, <software@mabwebdesign.com>\n"
			  );
		return 1;
	}
	
	int l, a;
	
	if((l = [arguments count]) <= 4) {
		NSLog(@"You must specify at least 4 arguments. The first two being the PDF files to combine, then the -o argument followed by the path to the output file.");
		return 1;
	}

	PDFDocument *mainDoc = [[PDFDocument alloc] initWithURL:[NSURL fileURLWithPath:[[arguments objectAtIndex:1] stringByExpandingTildeInPath]]];

	for(a = 2; a < l; a++) {
		if([[arguments objectAtIndex:a] isEqualToString:@"-o"]) {
			NSURL *outputFile = [NSURL fileURLWithPath:[[arguments objectAtIndex:a+1] stringByExpandingTildeInPath]];
			if([[NSFileManager defaultManager] fileExistsAtPath:[outputFile path]]) {//if the file already exists, check to make sure the user wants to overwrite it
				NSLog(@"The file: %@\nAlready exists. Do you want to overwrite it? (y/n)", outputFile);
				char buff[10];
				scanf("%c", buff);
				if(buff[0] != 'y' && buff[0] != 'Y') {
					return 2;
				}
			}
			
			if(![mainDoc writeToURL:outputFile])
				NSLog(@"Write to %@ failed", outputFile);
			break;
		}
		
		PDFDocument *tempDoc = [[PDFDocument alloc] initWithURL:[NSURL fileURLWithPath:[[arguments objectAtIndex:a] stringByExpandingTildeInPath]]];
		int b = 0, pages = [tempDoc pageCount];
		for(; b < pages; b++)
			{
			[mainDoc insertPage:[tempDoc pageAtIndex:b] atIndex:[mainDoc pageCount]];
			}
		
		//dont send the release message. 
		//If you add pages to another PDFDocument that are in another PDFDocument, and release the document that has the added pages (tempDoc in this case) your app will crash
		//the PDFDocument that got pages added to it (mainDoc in this case), must be released before the PDFDocuments that have the added pages are released (the tempDoc's in this case)
		[tempDoc autorelease]; 
	}

	[mainDoc release];
	
    [pool release];
    return 0;
}
