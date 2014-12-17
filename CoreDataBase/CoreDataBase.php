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

class SQL extends NSObject
{
	protected $type;
	protected $db;		// SQLite/MySQL access handle
	protected $dbname;	// current database name/file
	protected $delegate;	// the delegate (may be temporarily $this)
	protected $tables;	// collecting internal information

	public function open($url, &$error)
	{ // YES=ok
		NSLog($url);
		$c=parse_url($url);
		if($c === false)
			return false;	// invalid
		if($c['scheme'] == "mysql")
			{
			$this->type=$c['scheme'];
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
		if($c['scheme'] == "sqlite" || $c['scheme'] == "file")
			{
			// must be localhost, no user/password
			$this->dbname=$c['path'];	// file name
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

	public function setDelegate($d)
	{
	$this->delegate=$d;
	}

	public function delegate()
	{
	return $this->delegate;
	}

	public function query($sql, &$error)	// YES=ok
	{
	NSLog("SQL: ".$sql);
	if(mysqli_error($this->db))
		{
		NSLog(mysqli_error($this->db));
		return false;
		}
	$result=mysqli_query($this->db, $sql);
	NSLog("query done $result");
	if(mysqli_error($this->db))
		{
		NSLog(mysqli_error($this->db));
		return false;
		}
	NSLog("query ok");
	if(isset($this->delegate))
		{
		while($row=mysqli_fetch_array($result))
			{
			NSLog("call delegate with row");
			if($this->delegate->sql($this, $row))
				break;	// delegate did request to abort
			}
		}
	mysqli_free_result($result);
	return true;	// ok
	}

	public function quote($str)
	{ // quote argument string
		return "'".addslashes($str)."'";
	}

	public function quoteIdent($identifier)
	{ // quote table/column name
		return "`".$identifier."`";
	}

	private function sql($sqlobject, $record)
	{ // we are (temporarily) our own delegate
		$this->tables[]=$record["name"];	// collect table names
		return false;	// don't abort
	}

	public function tables(&$error)
	{
		$saved=$this->delegate;
		$this->delegate=$this;	// make us collect results in tables
		$this->tables=array();	// we collect here

		if($this->type == "mysql")

			$query="SELECT table_name AS name FROM information_schema.tables WHERE table_schema = ".$this->quote($this->dbname);	// MySQL
		else
			$query="SELECT name,sql FROM sqlite_master WHERE type=".$this->quote("table");
		if(!$this->query($query, $error))
			{
			$this->delegate=$saved;
			return null;
			}
		$this->delegate=$saved;
		return $this->tables;
	}

	public function databases(&$error)
	{ // ask for list of known databases
		if($this->type == "mysql")
			{
			$saved=$this->delegate;
			$this->delegate=$this;	// make us collect results in tables
			$this->tables=array();	// we collect here
			$query="SELECT DISTINCT table_schema AS name FROM information_schema.tables";	// MySQL
			if(!$this->query($query, $error))
				{
				$this->delegate=$saved;
				return null;
				}
			$this->delegate=$saved;
			return $this->tables;
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
	$this->flush();
	}
}

?>
