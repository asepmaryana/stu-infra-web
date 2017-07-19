<?php
class OutboxModel extends CI_Model 
{

	public $table	= 'outbox';

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
    
    function get_site_and_date($recipient, $from, $to)
    {
        if(is_array($recipient) && count($recipient)>0) $this->db->where_in('recipient', $recipient);
        elseif(!is_array($recipient) && $recipient != '' && $recipient != '_') $this->db->where('recipient', $recipient);
        $this->db->where('create_date >= ', $from.' 00:00:00');
        $this->db->where('create_date <= ', $to.' 23:59:59');
        $this->db->order_by('id', 'desc');
        return $this->db->get($this->table, 5, 0);
    }
    
    function get_site_and_date_limit($recipient, $limit, $offset)
    {
        if(is_array($recipient) && count($recipient)>0) $this->db->where_in('recipient', $recipient);
        elseif(!is_array($recipient) && $recipient != '' && $recipient != '_') $this->db->where('recipient', $recipient);
        $this->db->order_by('id', 'desc');
        return $this->db->get($this->table, $limit, $offset);
    }
    
    function get_last($recipient, $status='U')
    {
        if(is_array($recipient) && count($recipient)>0) $this->db->where_in('recipient', $recipient);
        elseif(!is_array($recipient) && $recipient != '' && $recipient != '_') $this->db->where('recipient', $recipient);
        $this->db->where('status', $status);
        $this->db->order_by('id', 'desc');
        return $this->db->get($this->table, '1', '0');
    }
    
    function get_unprocessed($status='U')
    {
        $this->db->where('status', $status);
        $this->db->order_by('id', 'asc');
        return $this->db->get($this->table);
    }
}
?>