<?php
class AlarmlogModel extends CI_Model 
{

	public $table	= 'alarm_log';

	function __construct()
	{
		parent::__construct();
	}
	
    function get_site_and_date($site_id, $from, $to)
    {
        if(is_array($site_id) && count($site_id)>0) $this->db->where_in('node_id', $site_id);
        elseif(!is_array($site_id) && $site_id != '' && $site_id != '_') $this->db->where('node_id', $site_id);
        $this->db->where('dtime >= ', $from.' 00:00:00');
        $this->db->where('dtime <= ', $to.' 23:59:59');
        $this->db->where('dtime_end IS NOT NULL');
        
        $this->db->order_by('dtime', 'asc');
        return $this->db->get($this->table.'_view');      
    }
    
    function get_site_alarm_and_date($site_id, $alarm_id, $from, $to)
    {
        if(is_array($site_id) && count($site_id)>0) $this->db->where_in('node_id', $site_id);
        elseif(!is_array($site_id) && $site_id != '' && $site_id != '_') $this->db->where('node_id', $site_id);
        
        if(is_array($alarm_id) && count($alarm_id)>0) $this->db->where_in('alarm_list_id', $alarm_id);
        elseif(!is_array($alarm_id) && $alarm_id != '' && $alarm_id != '_') $this->db->where('alarm_list_id', $alarm_id);
        
        $this->db->where('dtime >= ', $from.' 00:00:00');
        $this->db->where('dtime <= ', $to.' 23:59:59');
        $this->db->where('dtime_end IS NOT NULL');
        
        $this->db->order_by('dtime', 'asc');
        return $this->db->get($this->table.'_view');      
    }	
}
?>