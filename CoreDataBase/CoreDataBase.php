<?php

	/*
	 * CoreDataBase.framework
	 * (C) Golden Delicious Computers GmbH&Co. KG, 2013
	 * All rights reserved.
	 */

global $ROOT;	// must be set by some .app
require_once "$ROOT/System/Library/Frameworks/Foundation.framework/Versions/Current/php/Foundation.php";

if($GLOBALS['debug']) echo "<h1>CoreDataBase.framework</h1>";

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
*/

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

class SQLRowEnumerator extends	/* NSEnumerator */ NSObject
{
	protected $result;

// FIXME: handle http://php.net/manual/de/class.sqlite3result.php
// by inspecting the class of $r
// we could also subclass SQLRowEnumerator into _MySQLRowEnumerator and _SQLiteRowEnumerator

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

	public function allObjectsKorKey($column)
	{ // fetch all (remaining) rows and extract key
		$result=array();
		while($row=$this->nextObject())
			$result[]=$row[$column];
		return $result;
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
		NSLog($url);
		$c=parse_url($url);
		if($c === false)
			return false;	// invalid
		$this->type=$c['scheme'];
		if($this->type == "mysql")
			{
			$socket="/opt/local/var/run/mysql5/mysqld.sock";	// MySQL as installed by MacPorts
			NSLog("connect to ".$c['host']." ".$c['user']." ".$c['pass']);
			// FIXME: should only remove the /
			$this->dbname=basename($c['path']);
			$this->db=mysqli_connect("p:".$c['host'], $c['user'], $c['pass'], $this->dbname, ini_get("mysqli.default_port"), $socket);
			if(mysqli_connect_errno())
				{
				NSLog(mysqli_connect_error());
				// set error
				return false;
				}
			return true;
			}
		if($this->type == "sqlite" || $c['scheme'] == "file")
			{
			// must be localhost, no user/password
			$this->dbname=$c['path'];	// file name
			$this->db=new SQLite($this->dbname);
			return isset($this->db);
			}
		return false;	// we speak only MySQL
	}

	public function setDatabase($name)
	{ // change database (MySQL) or file (SQLite)
		if(mysqli_select_db($this->db, $name))
			{
			$this->dbname=$name;
			return true;
			}
		return false;
	}

	public function query($sql, &$error)
	{
	NSLog("SQL: ".$sql);
	if($this->type == "mysql")
		{
		if(mysqli_error($this->db))
			{
			NSLog(mysqli_error($this->db));
			return null;
			}
		$result=mysqli_query($this->db, $sql);
		NSLog("MySQL query done");
		if(mysqli_error($this->db))
			{
			NSLog(mysqli_error($this->db));
			return null;
			}
		NSLog("query ok");
		return new SQLRowEnumerator($result);
		}
	else
		{
		$result=$this->db->query($sql);
		if(!$result)
			{
			return null;
			}
		NSLog("MySQL query done");
		return new _SQLiteRowEnumerator($result);
		}
	}

	public function quote($str)
	{ // quote argument string
		return quote($str);
	}

	public function quoteIdent($identifier)
	{ // quote table/column name
		return quoteIdent($str);
	}

	public function tables(&$error)
	{
		if($this->type == "mysql")
			$query="SELECT table_name AS name FROM information_schema.tables WHERE table_schema = ".$this->quote($this->dbname);	// MySQL
		else
			$query="SELECT name,sql FROM sqlite_master WHERE type=".$this->quote("table");
		return $this->query($query, $error)->allObjectsForKey("name");
	}

	public function databases(&$error)
	{ // ask for list of known databases
		if($this->type == "mysql")
			{
			$query="SELECT DISTINCT table_schema FROM information_schema.tables";	// MySQL
			return $this->query($query, $error)->allObjectsForKey("table_schema");
			}
		if($this->type == "sqlite")
			return array($this->dbname);	// database file name/path
		return null;
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
