<?php
class SiteModel extends CI_Model 
{
	public $table	= 'node';

	function __construct()
	{
		parent::__construct();
	}
	
    function get_by_region($region_id)
	{
		if(is_array($region_id) && count($region_id) > 0) $this->db->where_in('subnet_id', $region_id);
        elseif(!is_array($region_id) && $region_id != '') $this->db->where('subnet_id', $region_id);
		return $this->db->get($this->table);
	}
    
    function get_list()
    {
        $this->db->select('id,name');
        $this->db->order_by('name', 'asc');
        return $this->db->get($this->table);
    }
    
    function count_all()
	{
		return $this->db->count_all($this->table);
	}
	
	function get_paged_list($limit = 10, $offset = 0)
	{
	    $this->db->select('n.*, s.name as region, c.name as customer');
        $this->db->join('subnet s', 'n.subnet_id=s.id', 'left');
        $this->db->join('customer c', 'n.customer_id=c.id', 'left');
        $this->db->order_by('n.name', 'asc');
        return $this->db->get($this->table.' n', $limit, $offset);
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