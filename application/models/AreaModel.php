<?php
class AreaModel extends CI_Model 
{
	public $table	= 'subnet';

	function __construct()
	{
		parent::__construct();
	}
	
    function get_list()
    {
        $this->db->select('id,name');
        $this->db->where('parent_id IS NOT NULL');
        $this->db->order_by('name', 'asc');
        return $this->db->get($this->table);
    }
    
    function count_all()
	{
	    $this->db->where('parent_id IS NOT NULL');
		return $this->db->count_all($this->table);
	}
	
	function get_paged_list($limit = 10, $offset = 0)
	{
	    $this->db->select('a.*, r.name as region');
        $this->db->where('a.parent_id IS NOT NULL');
        $this->db->join('subnet r', 'a.parent_id=r.id');
        $this->db->order_by('a.name', 'asc');
        return $this->db->get($this->table.' a', $limit, $offset);
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