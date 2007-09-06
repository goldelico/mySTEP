
#import <Cocoa/Cocoa.h>
#import "Locnode.h"

int main(int argc, const char *argv[])
{
	NSAutoreleasePool *arp=[NSAutoreleasePool new];
	FILE *f=popen("sqlite3 opengeodb.sqlite <<END\n"
				  "SELECT CONCAT(C.lat, ' ', C.lon, ' ', T.text_locale, ' ', T.text_type, ' ', T.text_val)\n"
				  "FROM geodb_coordinates AS C, geodb_textdata AS T\n"
				  "WHERE C.loc_id = T.loc_id\n"
				  "AND T.text_locale IS NOT NULL\n"
				  "LIMIT 1000;\n"
				  "END", "r");
	if(!f)
		{
		NSLog(@"can'r execute SQL command");
		return 1;
		}
	while(!feof(f))
		{
		double lat=0.0, lon=0.0;
		char locale[256]="locale";
		long type;
		char name[512]="name";
		if(fscanf(f, "%lf %lf %s %lu", &lat, &lon, locale, &type) == 0)
			continue;
		if(fgets(name, sizeof(name)-1, f) == NULL)
			continue;	// EOF
		// first char of name is blank, last is \n
		if(type == 500100000)
			NSLog(@"(%lf, %lf) %s %d %s", lat, lon, locale, type, name+1);	// Ort
		else if(type == 500700000)
			NSLog(@"(%lf, %lf) %s %d %s", lat, lon, locale, type, name+1);	// Gemeinde
//		else
//			NSLog(@"(%lf, %lf) %s %d *%s", lat, lon, locale, type, name);
		// add to location database
		}
	// write location database in binary format
	pclose(f);
	[arp release];
	return 0;
}

