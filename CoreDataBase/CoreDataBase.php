<?php

	/*
	 * CoreDataBase.framework
	 * (C) Golden Delicious Computers GmbH&Co. KG, 2013
	 * All rights reserved.
	 */

global $ROOT;	// must be set by some .app
require_once "$ROOT/System/Library/Frameworks/Foundation.framework/Versions/Current/php/Foundation.php";

echo "<h1>CoreDataBase.framework</h1>";

class ManagedObjectContext extends NSObject
{ // represents a data storage
	// can we manage different hosts and databases?
	// if we have a "database-handle"

	public function constructor($host, $user, $password, $database)
		{
echo "open $host - $user<p>";
		@mysql_pconnect($host, $user, $password);
		if(mysql_error())
			{
			echo "can't open connection to $host<p>";
			}
echo "select $database<p>";
		@mysql_select_db($database);
		if(mysql_error())
			{
			echo "can't select database $database<p>";
			}
		}

	public function addslashes($str)
		{ // add slashes for sql queries
		return addslashes($str);
		}

	public function quote($str)
		{ // quote argument for sql queries 
		return "'".($this->addslashes($str))."'"; 
		}

	public function query($query)
		{ // run query and report errors

		echo "query ".htmlentities($query)."<p>";

		$result=mysql_query($query);
		if(mysql_errno() != 0)
			{
			echo mysql_errno()." ".mysql_error()."<br>";
			echo $query."<br>";
			}
		return $result;
		}

	public function entity($table, $primarykey)
		{
		return new ManagedObjectEntity($this, $table, $primarykey);
		}
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
		if($where != NULL)
			$query .= " where $where";
		if($group != NULL)
			$query .= " group by $group";
		// having?
		if($order != NULL)
			$query .= " order by $order";
		if($limit > 0)
			$query .= " limit ".$context->quote($limit);
		$result=$_context->query($query);
		$mo=array();
		while($row=mysql_fetch_array($result))
			$mo[$row[$this->primarykey]]=new ManagedObject($this, $row);	// did already load - we should not be able to set values through such an object!!!
		mysql_free_result($result); 
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
	protected $filename;
	protected $delegate;
	protected $db;		// SQLite access handle - MySQL database name
	protected $tables;

	public function open($error)
	{ // YES=ok

		// FIXME: MySQL we can select only different databases within a single server!
		// so we must check that multiple instances refer to the same host/user/password

		NSLog($this->filename);
		$c=parse_url($this->filename);
		if($c === false)
			return false;	// invalid
		if($c['scheme'] != "mysql")
			return false;	// we speak only MySQL
		$this->type=$c['scheme'];
		if($c['host'] == "localhost")
			$c['host']=":/opt/local/var/run/mysql5/mysqld.sock";	// MySQL as installed by MacPorts
		NSLog("connect to ".$c['host']." ".$c['user']." ".$c['pass']);
		@mysql_pconnect($c['host'], $c['user'], $c['pass']);
		NSLog("database: ".$this->db);
		if(mysql_error())
			{
			NSLog(mysql_error());
			// set error
			return false;
			}
		$this->db=basename($c['path']);		// to select a specific database
		return true;
	}

	public function setDelegate($d)
	{
	$this->delegate=$d;
	}

	public function delegate()
	{
	return $this->delegate;
	}

	public function query($sql, $error)	// YES=ok
	{
	NSLog("SQL: ".$sql);
	mysql_select_db($this->db /* , $link? */);
	NSLog("select_db ".$this->db." done");
	if(mysql_error())
		{
		NSLog(mysql_error());
		return false;
		}
	$result=mysql_query($sql);
	NSLog("query done $result");
	if(mysql_error())
		{
		NSLog(mysql_error());
		return false;
		}
	NSLog("query ok");
	if(isset($this->delegate))
		{
		while($row=mysql_fetch_array($result))
			{
			NSLog("call delegate with row");
			if($this->delegate->sql($this, $row))
				break;	// delegate did request to abort
			}
		}
	mysql_free_result($result);
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

	public function tables($error)
	{
		$saved=$this->delegate;
		$this->delegate=$this;	// make us collect results in tables
		$this->tables=array();	// we collect here
		if($this->type == "mysql")
			$query="SELECT table_name AS name FROM information_schema.tables WHERE table_schema = ".$this->quote($this->db);	// MySQL
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

	public function __construct($url)
	{
	parent::__construct();
	// check for mysql: scheme
	$this->filename=$url;
	}

	public function __destruct()
	{
	$this->flush();
	}
}

?>
