<?php
class AlarmListModel extends CI_Model 
{
	public $table	= 'alarm_list';

	function __construct()
	{
		parent::__construct();
	}
	
    function get_list()
    {
        $this->db->select('al.*, s.name as severity');
        $this->db->join('severity s', 'al.severity_id=s.id', 'left');
        $this->db->order_by('al.name', 'asc');
        return $this->db->get($this->table.' al');      
    }
    
    function count_all()
	{
		return $this->db->count_all($this->table);
	}
	
	function get_paged_list($limit = 10, $offset = 0)
	{
	    $this->db->select('al.*, s.name as severity');
        $this->db->join('severity s', 'al.severity_id=s.id', 'left');
		$this->db->order_by('al.name','asc');
		return $this->db->get($this->table.' al', $limit, $offset);
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