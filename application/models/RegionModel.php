<?php
class RegionModel extends CI_Model 
{
	public $table	= 'subnet';

	function __construct()
	{
		parent::__construct();
	}
	
    function get_list()
    {
        $this->db->select('id,name');
        $this->db->where('parent_id IS NULL');
        $this->db->order_by('name', 'asc');
        return $this->db->get($this->table);
    }
    
    function count_all()
	{
	    $this->db->where('parent_id IS NULL');
		return $this->db->count_all($this->table);
	}
	
	function get_paged_list($limit = 10, $offset = 0)
	{
	    $this->db->select('r.*, c.name as customer');
        $this->db->join('customer c', 'r.customer_id=c.id', 'left');
        $this->db->where('r.parent_id IS NULL');
        $this->db->order_by('r.name', 'asc');
        return $this->db->get($this->table.' r', $limit, $offset);
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