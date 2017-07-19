<?php
class RoleModel extends CI_Model 
{
	// table name
	public $table	= 'role';

	function __construct()
	{
		parent::__construct();
	}
	
    function get_all()
	{
	    $this->db->select('id,name');
        $this->db->where('id not in(1)');
        $this->db->order_by('name','asc');
		return $this->db->get($this->table);
	}
    
	function count_all()
	{
	    $this->db->where('id not in(1)');
		return $this->db->count_all($this->table);
	}
	
	function get_paged_list($limit = 10, $offset = 0)
	{
	    $this->db->where('id not in(1)');
		$this->db->order_by('name','asc');
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
		return $this->db->update($this->table, $data);
	}
    
    function delete($id)
	{
		$this->db->where('id', $id);
		return $this->db->delete($this->table);
	}
}
?>