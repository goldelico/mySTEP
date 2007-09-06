all:	GeoDB.data

clean:
	rm -f extract opengeodb.sqlite GeoDB.data

opengeodb.sql.gz:
	# somehow fetch from internet
	
opengeodb.sqlite:	opengeodb.sql.gz
	gunzip -c opengeodb.sql.gz | sed -e '/TYPE=InnoDB CHARACTER SET utf8/s/TYPE=InnoDB CHARACTER SET utf8//p' | sqlite3 opengeodb.sqlite
	# echo done!
	sqlite3 opengeodb.sqlite <<END\
	.tables\
	END\

extract:	extract.m Locnode.m Locnode.h
	cc -o extract extract.m Locnode.m -framework Cocoa -lobjc

GeoDB.data:	Makefile extract opengeodb.sqlite
	./extract

check:
	sqlite3 opengeodb.sqlite <<END\
		SELECT C.lat, C.lon, T.text_locale, T.text_type, T.text_val, CONCAT(C.lat, ' ', C.lon, ' ', T.text_locale, ' ', T.text_type, ' ', T.text_val)\
		FROM geodb_coordinates AS C, geodb_textdata AS T\
		WHERE C.loc_id = T.loc_id AND T.text_locale IS NOT NULL\
		LIMIT 100;\
		END
