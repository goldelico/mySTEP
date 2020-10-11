<?php

	/*
	 * CoreDataBase.framework
	 * (C) Golden Delicious Computers GmbH&Co. KG, 2013
	 * All rights reserved.
	 */

global $ROOT;	// must be set by some .app
require_once "$ROOT/System/Library/Frameworks/Foundation.framework/Versions/Current/php/Foundation.php";

if($GLOBALS['debug']) echo "<h1>CoreDataBase.framework</h1>";

/* OLD

class ManagedObjectContext extends NSObject
{ // represents a data storage
}

class ManagedObjectEntity extends NSObject

// Eigentlich EntityDescription?

{
	protected $context;	// database connection
	protected $table;	// the table we represent
// Keys und Abfragen sollten durch das Datenmodell beschrieben werden!
	protected $primaryKey;	// name of primary key column

	protected $foreignEntity;	// to build a chain/network (?) of entities
	
	public function get($key, $fetch=false)
		{ // fetch a single value for the given key
echo "get ".htmlentities($key)."<p>";
		$mo=new ManagedObject($this, $key);
		if($fetch)
			$mo->fetch();
		if(!exists)
			$mo=$this->newObject();		// create new entry
		return $mo;
		}
	
	public function newObject()
		{ // create new empty entry with uuid key
echo "new<p>";
		// make uuid or unique index
			$key=uuid();
			$mo=new ManagedObject($this, $key);
			return $mo;
		}

	// Zugriff als NSTableDataSource erlauben?

// das sollte ŸberflŸssig sein!
// genaugenommen ist das ein (beschreibbarer) SQL-View was wir hier versuchen nachzubilden

	public function getBySQL($where=NULL, $order=NULL, $group=NULL, $limit=0)
		{
		$query="select * from `$this->_table`";
		return $mo;
		}

	public function getByColumn($colname, $key, $limit=0)
		{
		return $this->getBySQL("`$colname` = '$key'", NULL, NULL, $limit);
		}

/*
	public function fields()
		{
		for($i=0; $i<mysql_num_fields($result); $i=$i+1)
			{
			$f=mysql_field_name($result, $i);
			}
		}
* /

	public function constructor($context, $table, $primarykey)
		{
		$this->context=$context;
		$this->table=$table;
		$this->primarykey=$primarykey;
		}

}

class ManagedObject extends NSObject
{ // represents a single row of a database
	protected $entity;
	protected $key;
	protected $timestamp;
	protected $row;
	protected $fetched;
	protected $dirty;

	public function fetch()
		{
		echo "query ".htmlentities($fetch)."<p>";
		if($this->_fetched)
			return;
		$this->row=$this->entity->getByColumn($this->entity->primarykey, $this->key, 1);
		}

	public function flush()
		{
		if($this->dirty)
		// use $this->entity->quote("");
			$this->entity->query("update `".$this->entity->table."` set `$prop` = '$value'... where `$_row`='$key'");
		$this->dirty=false;
		}

	public function key()
		{
		return $this->_key;
		}

	public function setKey($key)
		{
		$this->flush();
		$this->key=$key;
		$this->fetched=false;
		}

	public function __set($prop, $value)
		{
		echo "__set ".htmlentities($prop)." = ".htmlentities($value)."<p>";
		$this->fetch();
		$this->row[$prop] = $value;
		$this->dirty=true;	// we could collect columns that have been changed
		// we can also notify the context that this entity has been updated
		}

	public function __get($prop)
		{
		echo "__get ".htmlentities($prop)."<p>";
		$this->fetch();
		return (isset($this->row[$prop])) ? $this->row[$prop] : null;
		}

	public function __construct($entity, $key)
		{
      		parent::__construct();
		$this->entity=$entity;
		$this->key=$key;
		}

	public function __destruct()
		{
		$this->flush();
		}

}

OLD */

class _CSV
{
	protected $file;
	protected $separator;
	protected $enclosure;
	protected $columns;
	protected $rows;
	static $cache;

	public static function fileTest($file)
	{ // check if we can process this file as a table name
		$c=pathinfo($file);
		if(!isset($c['extension']))
			return false;	// file w/o extension
		return $c['extension'] == "csv" || $c['extension'] == "tsv" || $c['extension'] == "ssv" ||
			$c['extension'] == "xls" || $c['extension'] == "html";
	}

	public static function newCSV($directory, $table)
	{
		$key="$directory/$table";
		if(isset(_CSV::$cache[$key]))
			return _CSV::$cache[$key];	// found in cache
		$csv=new _CSV();
		if(!$csv->open($directory, $table))
			return null;	// failed to open
		_CSV::$cache[$key]=$csv;
		return $csv;
	}

	public function open($directory, $table)
	{
// echo "open $directory table $table\n";
		if(($dh = opendir($directory)) === false)
			return false;	// failed to open directory
		while (($file = readdir($dh)) !== false)
			{ // search for table name and .csv or .tsv extension
			$c=pathinfo($file);
// echo "try $file\n";
			if(_CSV::fileTest($file))
				{ // candidate
				if($c['filename'] == $table)
					break;	// found
				}
			}
		closedir($dh);
// echo "file $file\n";
		if($file === false)
			return null;	// not found
		$this->file=$directory."/".$file;
		$this->separator=",";
		$this->enclosure="\"";
		if(substr($file, -4) == ".tsv")
			{
			$this->separator="\t";
			$this->enclosure="\n";	// should never occur
			}
		if(substr($file, -4) == ".ssv")
			{
			$this->separator=";";
			}
		else if(substr($file, -4) == ".xls" || substr($file, -5) == ".html")
			{ // try to read html
			$doc = new DOMDocument();
			$doc->strictErrorChecking = FALSE;
			if(!$doc->loadHTMLFile($this->file))
				{
				NSLog("could not process $this->file as html");
				return false;
				}
			$body=$doc->getElementsByTagName('body')->item(0);	// first
			$table=$body->getElementsByTagName('table')->item(0);
			$this->columns=array();
			$this->rows=array();
			foreach($table->getElementsByTagName('tr') as $tr)
				{
// print_r($tr);
				foreach($tr->getElementsByTagName('th') as $th)
					{
// print_r($th);
					$this->columns[]=$th->textContent;
					}
				unset($columns);
				$idx=0;
				foreach($tr->getElementsByTagName('td') as $td)
					{
// print_r($td);
					if(count($this->columns) > 0)	// names are known
						$columns[$this->columns[$idx++]]=$td->textContent;
					else
						$columns[$idx++]=$td->textContent;
// echo $td->textContent."\n";
					}
				if(isset($columns))
					{
					if(count($this->columns) == 0)	// column names with <td>
						$this->columns=$columns;
					else
						$this->rows[]=$columns;
					}
				}
			return true;
			}
		if(!$handle = @fopen($this->file, "r"))
			{
			NSLog("could not read $this->file");
			return false;
			}
		if(($this->columns = fgetcsv($handle, 0, $this->separator, $this->enclosure)) === false)
			return false;
// _NSLog($this->separator);
// _NSLog($this->columns);
		$this->rows[]=array();
		while(($values = fgetcsv($handle, 0, $this->separator, $this->enclosure)) !== false)
			{
// print_r($values);
			$row=array();
			for($c=0; $c<count($this->columns); $c++)
				{ // make $rows an array of arrays indexed by the column names
				if($c<count($values)) $val=$values[$c];
				else $val="";	// missing entry
				$row[$this->columns[$c]]=$val;	// use column names as new index
				}
// print_r($row);
			$this->rows[]=$row;
			}
		fclose($handle);
//		_NSLog("opened $file ".count($this->rows)." rows ".count($this->columns)." cols");
		return true;
	}

// for better transaction separation
// we should open() + change + save()
// and/or allow to lock a file
// i.e. lock() + open() + change + save() + unlock()

	public function save()
	{ // save to file
		// NSArray write?
		if(!$handle = @fopen($this->file, "w"))
			{
			NSLog("could not write $this->file");
			return false;
			}
		if(substr($this->file, -4) == ".xls" || substr($this->file, -5) == ".html")
			{ // write as html table so that we can open in EXCEL/OpenOffice

// Alternative: DOMDocument aufbauen und dann schreiben

			fprintf(handle, "<head>\n");
			fprintf(handle, "</head>\n");
			fprintf(handle, "<body>\n");
			fprintf(handle, "<table>\n");
			fprintf(handle, "<tr>\n");
			foreach($this->columns as $col)
				fprintf(handle, "<th>".htmlentities($col)."</th>\n");
			fprintf(handle, "</tr>\n");
			foreach($this->rows as $record)
				{
				fprintf(handle, "<tr>\n");
				foreach($this->columns as $col)
					fprintf(handle, "<td>".htmlentities($record[$col])."</td>\n");
				fprintf(handle, "</tr>\n");
				}
			fprintf(handle, "</table>\n");
			fprintf(handle, "</body>\n");
			fclose($handle);
			return true;	// OK
			}
		if(!fputcsv($handle, $this->columns, $this->separator, $this->enclosure))
			{
			fclose($handle);
			return false;
			}
		foreach($this->rows as $record)
			if(!fputcsv($handle, $record, $this->separator, $this->enclosure))
				{
				fclose($handle);
				return false;
				}
		fclose($handle);
		return true;	// OK
	}

	public function columns() { return $this->columns; }
	public function rows() { return $this->rows; }
	public function numberOfColumns() { return count($this->columns); }
	public function numberOfRows() { return count($this->rows); }

/* do we need this??? - why does it not depend on $table? */

	public function selectFirstWhereColumnIsValue($column, $value)
	{ // SELECT * WHERE column = value
//		echo "SELECT * WHERE $column = $value\n";
		foreach($this->rows as $row)
			if($row[$column] == $value)
				return $row;
		return null;
	}

	public function selectColumn($column)
	{ // SELECT column
//		echo "SELECT $column\n";
		foreach($this->rows as $row)
			$r[]=$row[$column];
		return $r;
	}

	public function create($directory, $table, $columns)
	{
		if(isset($this->columns))
			return false;	// already opened!
		$c=pathinfo($table);
		if(!isset($c['extension']))
			$file=$directory."/".$table.".csv";
		else
			$file=$directory."/".$table;	// use suffix by table name
		if(file_exists($file))
			return false;	// table already esists
		$this->file=$file;
		$this->separator=",";
		$this->enclosure="\"";
		$this->columns=$columns;
		$this->rows=array();	// empty
	}

	// insert, update records

}

class SQLRowEnumerator extends	/* NSEnumerator */ NSObject
{
	protected $result;

	public function __construct($r)
	{
		parent::__construct();
		$this->result=$r;
	}

	public function __destruct()
	{
		mysqli_free_result($this->result);
	}

/*
 * use as
 * $row=$db->query(...)->nextObject() -- get single (first) row
 * $rows=$db->query(...)->allObjects() -- get all rows (you should use SELECT ... LIMIT)
 * $enum=$db->query(); while($row=$enum->nextObject()) body(); -- loop over all rows
 */

	public function nextObject()
	{ // fetch next row
		return mysqli_fetch_array($this->result);
	}

	public function allObjects()
	{ // fetch all (remaining) rows
		$result=array();
		while($row=$this->nextObject())
			$result[]=$row;
		return $result;
	}

	public function allObjectsForKey($column)
	{ // fetch all (remaining) rows and extract by given key
		$result=array();
		while($row=$this->nextObject())
			$result[]=$row[$column];
		return $result;
	}

	public function fields()
	{ // get field names
		$finfo = mysqli_fetch_fields($this->result);
		$f=array();
		foreach ($finfo as $val)
			$f[]=$val->name;
		return $f;
	}
}

class _SQLiteRowEnumerator extends SQLRowEnumerator
{
	public function __destruct()
	{
		// nothing to destruct explicitly
	}

	public function nextObject()
	{ // fetch next row
		return $result->fetchArray();
	}
}

class _CSVRowEnumerator extends SQLRowEnumerator
{
	public function __construct($r)
	{
		parent::__construct($r);
		reset($this->result);
	}

	public function __destruct()
	{
		// nothing to destruct explicitly
	}

	public function nextObject()
	{ // fetch next row
		return next($this->result);	// use PHP enumertor
	}
}

function quote($str)
	{ // quote argument string
		return "'".addslashes($str)."'";
	}

function quoteIdent($identifier)
	{ // quote table/column name
		return "`".$identifier."`";
	}

class SQL extends NSObject
{
	protected $type;
	protected $db;	// SQLite/MySQL access handle
	protected $dbname;	// current database name/file

	public function open($url, &$error)
	{ // YES=ok
// don't enable if you have some $_GET['DEBUG'] magic in the App or the DB password is revealed to the Web
// NSLog($url);
		$c=parse_url($url);
		if($c === false)
			return false;	// invalid
		$this->type=$c['scheme'];
		if($this->type == "mysql")
			{
			$socket="/opt/local/var/run/mysql57/mysqld.sock";	// MySQL as installed by MacPorts
			if(!file_exists($socket))
				$socket="/opt/local/var/run/mysql56/mysqld.sock";	// MySQL as installed by MacPorts
			if(!file_exists($socket))
				$socket="/opt/local/var/run/mysql5/mysqld.sock";	// MySQL as installed by MacPorts
// don't enable if you have some $_GET['DEBUG'] magic in the App or the DB password is reveilled to the Web
// NSLog("connect to ".$c['host']." ".$c['user']." ".$c['pass']);
			// FIXME: should only remove the /
			if(isset($c['path']))
				$this->dbname=basename($c['path']);
			$this->db=@mysqli_connect("p:".$c['host'], $c['user'], $c['pass'], $this->dbname, ini_get("mysqli.default_port"), $socket);
			if(mysqli_connect_errno())
				{
				$error=mysqli_connect_error();
				NSLog($error);
				return false;
				}
			$this->query("SET NAMES 'utf8'", $error);
			return true;
			}
		if($this->type == "sqlite")
			{
			// must be localhost, no user/password
			$this->dbname=$c['path'];	// file name
			$this->db=new SQLite($this->dbname);
			return isset($this->db);
			}
		if($this->type == "file")
			{ // csv, tsv, html etc.
			$this->dbname=$c['path'];	// directory name
			return file_exists($c['path']);	// should we base on NSFileManager?
			}
		return false;	// not supported
	}

	public function setDatabase($name)
	{ // change database (MySQL) or file (SQLite)
		if($this->type == "mysql")
			{
			if(!mysqli_select_db($this->db, $name))
				return false;	// can't select
			$this->dbname=$name;
			return true;
			}
		if($this->type == "sqlite")
			return false;	// no database to select
		if($this->type == "file")
			return false;	// no database to select
		return false;
	}

	/* this is our miniparser for SQL */
	function eat($key, &$sql)
	{
		$len=strlen($key);
		while(substr($sql, 0, 1) == " " || substr($sql, 0, 1) == "\n")
			$sql=substr($sql, 1);	// eat whitespace
		if($key == "")
			return true;	// just called to skip whitespace
		if(strcasecmp(substr($sql, 0, $len), $key) == 0)
			{ // found
			$sql=substr($sql, $len);	// eat keyword
NSLog("sql: $key");
			return true;
			}
		return false;
	}

	function sqlIdent(&$sql)
	{ // get identifier - potentially quoted in ``
		$this->eat("", $sql);	// skip any whitespace
NSLog("try to get ident: $sql");
		if(preg_match("|^([a-zA-Z_][a-zA-Z_0-9]*)|", $sql, $match))
			{ // standard identifier only
			$ident=$match[1];
			$sql=substr($sql, strlen($ident));	// remove ident
			}
		else if(preg_match("|^`([^`]*)`|", $sql, $match))
			{ // accept any character except `
			$ident=$match[1];
			$sql=substr($sql, strlen($ident)+2);	// remove ident and ``
			}
		else
			$ident=null;
NSLog("sql: $ident");
		return $ident;
	}

	function sqlValue(&$sql, $row)
	{ // get value
		if($this->eat("NOT", $sql))
			return !$this->sqlConditional($sql, $row);
		if($this->eat("(", $sql))
			{
			$val=$this->sqlValue($sql, $row);
			if(!$this->eat(")", $sql))
				;	// syntax error
			return $val;
			}
		if(($ident=$this->sqlIdent($sql)) != null)
			{
			if(!isset($row[$ident]))
				return null;	// column does not exist
			return $row[$ident];
			}
		if(preg_match("|^'(.*)'|", $sql, $match))
			{ // quoted string (does not handle escape sequences and embedded ' yet)
			$str=$match[1];
			$sql=substr($sql, strlen($str)+2);	// remove string
			return $str;
			}
		if(preg_match("|^'(-?[0-9][0-9]*)'|", $sql, $match))
			{
			$val=0+$match[1];	// convert to PHP number
			NSLog("sql: $val");
			return $val;
			}
		return null;
	}

	// there should be arithmetic in between

	function sqlComparison(&$sql, $row)
	{ // evaluate column = value
		if($this->eat("(", $sql))
			{
			$val=$this->sqlConditional($sql, $row);
			if(!$this->eat(")", $sql))
				;	// syntax error
			return $val;
			}
		$l=$this->sqlValue($sql, $row);
		if($this->eat("="))
			return 	$l === $this->sqlValue($sql, $row);
		if($this->eat("<>"))
			return 	$l !== $this->sqlValue($sql, $row);
		if($this->eat("<"))
			return 	$l < $this->sqlValue($sql, $row);
		if($this->eat("<="))
			return 	$l <= $this->sqlValue($sql, $row);
		if($this->eat(">"))
			return 	$l > $this->sqlValue($sql, $row);
		if($this->eat(">="))
			return 	$l >= $this->sqlValue($sql, $row);
		return false;	// syntax error!
	}

	function sqlLogical(&$sql, $row)
	{ // evaluate AND
		if(!$this->sqlComparison($sql, $row))
			return false;	// first non-match is sufficient
		while($this->eat("AND"))
			{
			if(!$this->sqlComparison($sql, $row))
				return false;	// any non-match is sufficient
			}
		return true;	// all conditions were true
	}

	function sqlConditional(&$sql, $row)
	{ // evaluate OR
		if($this->sqlLogical($sql, $row))
			return true;	// first match is sufficient
		while($this->eat("OR"))
			{
			if($this->sqlLogical($sql, $row))
				return true;	// any match is sufficient
			}
		return false;	// no condition was true
	}

	function sqlColumns(&$sql)
	{
		if($this->eat("*", $sql))
			return array("*");	// special case
		$cols=array();
		do
			{
			$ident=$this->sqlIdent($sql);
			if(is_null($ident))
				return null;	// syntax error
			$cols[]=$ident;
			}
		while($this->eat(",", $sql));
		return $cols;
	}

	// we could use this for simple subqueries e.g. WHERE value IN (SELECT something)

	function sqlSelect(&$sql)
	{ // SELECT columns, ... FROM table WHERE condition LIMIT n
		/* parse */
		// $distinct=$this->eat("DISTINCT", $sql);	// hm. this requires filtering columns first and checking for duplicates on the where filter
		$cols=$this->sqlColumns($sql);	// parse columns list
		if(is_null($cols))
			return null;
		if(!$this->eat("FROM", $sql))
			return null;	// syntax error
		$table=$this->sqlIdent($sql);
		if(is_null($table))
			return null;
		$hasWhere=$this->eat("WHERE", $sql);
		$w=$sql;	// remember a copy of the WHERE clause for repeated evaluation
		if($hasWhere)
			$this->sqlConditional($sql, $row);	// process once
		if($this->eat("LIMIT", $sql))
			$limit=$this->sqlValue($sql, array());	// we don't know the columns yet
		else
			$limit=-1;	// never becomes 0 (unless we wrap around for integers)
		/* open table and fetch/filter results */
		if(($db=_CSV::newCSV($this->dbname, $table)) == null)
			return null;	// table does not exit
		if($hasWhere || $limit >= 0)
			{ // filter rows
			$where=array();
			foreach($db->rows() as $row)
				{
				if($limit-- == 0)
					break;	// enough rows copied
				$w=$sqlw;	// $w will be modified while parsing
				if(!$hasWhere || $this->sqlConditional($w, $row))
					$where[]=$row;	// include
				}
			}
		else
			$where=$db->rows();	// no WHERE or LIMIT clause
		if($cols[0] != '*')
			{ // filter columns
			$result=array();
			foreach($where as $row)
				{
				$r=array();
				foreach($cols as $col)
					// FIXME: what about case sensitivity of column names?
					$r[$col]=$row[$col];	// only specified columns
				$result[]=$r;
				}
			return $result;	// fetch and return all rows
			}
		return $where;
		}

	public function query($sql, &$error)
	{
	NSLog("SQL: ".$sql);
	if($this->type == "mysql")
		{
		$result=mysqli_query($this->db, $sql);
		if($result === FALSE)
			{ // failed
			NSLog("query $sql failed");
			$error="MySQL query failed: ".mysqli_error($this->db);
			return false;
			}
		if($result === TRUE)
			{ // not a SELECT succeeded
			$error="MySQL query succeeded";
			return true;
			}
		NSLog("MySQL query done");
		if(mysqli_error($this->db))
			{
			NSLog("query $sql failed: ".mysqli_error($this->db));
			$error="MySQL query failed: ".mysqli_error($this->db);
			return null;
			}
		$error="query ok";
		return new SQLRowEnumerator($result);
		}
	if($this->type == "sqlite")
		{
		$result=$this->db->query($sql);
		if(!$result)
			{
			return null;
			}
		$error="MySQL query done";
		return new _SQLiteRowEnumerator($result);
		}
	if($this->type == "file")
		{ // decode some very simple SQL commands and process on csv/.tsv files in given directory
		if($this->eat("SELECT", $sql))
			{
			$rows=$this->sqlSelect($sql);
			if(is_null($rows)) return null;	// some error
			return new _CSVRowEnumerator($rows);	// present as enumerator
			}
		if($this->eat("CREATE", $sql))
			;
		if($this->eat("INSERT", $sql))
			;
		if($this->eat("UPDATE", $sql))
			;
		if($this->eat("DELETE", $sql))
			;
NSLog("can't process for CSV file: $sql");
		}
	return null;
	}

	public function quote($str)
	{ // quote argument string
		return quote($str);
	}

	public function quoteIdent($identifier)
	{ // quote table/column name
		return quoteIdent($identifier);
	}

	public function columns($table, &$error)
	{ // get list of columns for table
		if($this->type == "mysql")
			$query="SELECT column_name AS name FROM information_schema.columns WHERE table_schema = ".$this->quote($this->dbname)." AND table_name = ".$this->quote($table);	// MySQL
		else if($this->type == "sqlite")

// FIXME:
			$query="SELECT name,sql FROM sqlite_master WHERE type=".$this->quote("table");
		else if($this->type == "file")
			{
			$db=new _CSV();
			if(!$db->open($this->dbname, $table))
				return null;	// table does not exit
			return $db->columns();
			}
		else
			return null;
		return $this->query($query, $error)->allObjectsForKey("name");
	}

	public function tables(&$error)
	{ // get all tables in current database
		if($this->type == "mysql")
			$query="SELECT table_name AS name FROM information_schema.tables WHERE table_schema = ".$this->quote($this->dbname);	// MySQL
		else if($this->type == "sqlite")
			$query="SELECT name,sql FROM sqlite_master WHERE type=".$this->quote("table");
		else if($this->type == "file")
			{ // return all files with .csv, .tsv etc. suffix
			$tables=array();
			if($dh = opendir($this->dbname))
				{
				while (($file = readdir($dh)) !== false)
					if(_CSV::fileTest($file))
// FIXME: strip off suffix!
						$tables[]=$file;
				}
			closedir($dh);
			return $tables;
			}
		else
			return null;
		return $this->query($query, $error)->allObjectsForKey("name");
	}

	public function createTable(&$error, $name, $columns)
	{
		$cmd="CREATE TABLE ".$this->quote(name);
		$cmd.=" (";
		$first=true;
		foreach($columns as $col => $properties)
			{
			if(!$first)
				$cmd.=",";
			$cmd.=$this->quote($col)." $properties";
			$first=false;
			}
		$cmd.=" )";
		$cmd.=" CHARACTER SET utf8 COLLATE utf8_general_ci";
		return null;
	}

	public function databases(&$error)
	{ // ask for list of known databases
		if($this->type == "mysql")
			{
			$query="SELECT DISTINCT table_schema FROM information_schema.tables";	// MySQL
			return $this->query($query, $error)->allObjectsForKey("table_schema");
			}
		if($this->type == "sqlite")
			return array($this->dbname);	// SQLite: database file name/path
		if($this->type == "file")
			return array($this->dbname);	// SQLite: database file name/path
		return null;
	}

	public function insert($table, $values, &$error)
	{ // insert record (NSDictionary with appropriate column names)
		$query="INSERT INTO ".quoteIdent($table);
		$query.=" SET ";
		$first=true;
		foreach($values as $column => $value)
			{
			if(!$first)
				$query.=",";
			$query.=" ".quoteIdent($column)." = ".quote($value);
			$first=false;
			}
// _NSLog("insert: $query");
		return $this->db->query($query, $error) !== false;
	}

	public function __construct()
	{
	parent::__construct();
	}

	public function __destruct()
	{
	}
}

?>
