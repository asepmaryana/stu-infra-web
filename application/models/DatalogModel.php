<?php
class DatalogModel extends CI_Model 
{

	public $table	= 'data_log';

	function __construct()
	{
		parent::__construct();
	}
	
    function save($data)
	{
		return $this->db->insert($this->table, $data);		
	}
    
    function get_site_and_date($site_id, $from, $to)
    {
        if(is_array($site_id) && count($site_id)>0) $this->db->where_in('node_id', $site_id);
        elseif(!is_array($site_id) && $site_id != '' && $site_id != '_') $this->db->where('node_id', $site_id);
        
        if($from == $to) $this->db->where("to_char(dtime,'YYYY-MM-DD')", $from);
        else {
            $this->db->where('dtime >= ', $from.' 00:00:00');
            $this->db->where('dtime <= ', $to.' 23:59:59');
        }
        $this->db->order_by('dtime', 'asc');
        return $this->db->get($this->table.'_view');      
    }
    
	function clear()
	{
		return $this->db->truncate($this->table);
	}
}
?>