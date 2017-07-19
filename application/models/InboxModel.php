<?php
class InboxModel extends CI_Model 
{

	public $table	= 'inbox';

	function __construct()
	{
		parent::__construct();
	}
	
	function save($data)
	{
		return $this->db->insert($this->table, $data);		
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
	
	function clear()
	{
		return $this->db->truncate($this->table);
	}
    
    function get_site_and_date($sender, $from, $to)
    {
        if(is_array($sender) && count($sender)>0) $this->db->where_in('sender', $sender);
        elseif(!is_array($sender) && $sender != '' && $sender != '_') $this->db->where('sender', $sender);
        $this->db->where('message_date >= ', $from.' 00:00:00');
        $this->db->where('message_date <= ', $to.' 23:59:59');
        $this->db->order_by('message_date', 'asc');
        return $this->db->get($this->table);
    }
}
?>