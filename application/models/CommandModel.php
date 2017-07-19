<?php
class CommandModel extends CI_Model 
{
	public $table	= 'command';

	function __construct()
	{
		parent::__construct();
	}
	
	function count_all()
	{
		return $this->db->count_all($this->table);
	}
	
    function get_list()
	{
	    $this->db->order_by('id','asc');
		return $this->db->get($this->table);
	}
    
	function get_paged_list($limit = 10, $offset = 0)
	{
		return $this->db->get($this->table, $limit, $offset);
	}

	function get_by_id($id)
	{
		$this->db->where('id', $id);
		return $this->db->get($this->table);
	}
	
	function save($data)
	{
		$this->db->insert($this->table, $data);
		return $this->db->insert_id();
	}
	
	function update($id, $data)
	{
		$this->db->where('id', $id);
		$this->db->update($this->table, $data);
	}
	
	function delete($id)
	{
		$this->db->where('id', $id);
		$this->db->delete($this->table);
	}
}
?>