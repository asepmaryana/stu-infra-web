<?php
class SubnetModel extends CI_Model 
{
	// table name
	public $table	= 'subnet';

	function __construct()
	{
		parent::__construct();
	}
	
    function get_regions()
	{
	    $this->db->where('parent_id is null');
        $this->db->order_by('name','asc');
		return $this->db->get($this->table);
	}
    
    function get_areas($regions_id)
	{
	    if(is_array($regions_id) && count($regions_id)>0) $this->db->where_in('parent_id', $regions_id);
	    elseif(!is_array($regions_id) && $regions_id != '') $this->db->where('parent_id', $regions_id);
        $this->db->order_by('name','asc');
		return $this->db->get($this->table);
	}
    
    function get_sites()
	{
	    $this->db->where('parent_id is not null');
		return $this->db->get($this->table);
	}
    
    function get_total_site()
	{
	    $this->db->select('count(id) as total');
        $rs = $this->db->get('site_view');
        if($rs->num_rows()>0) {
            $row = $rs->row();
            return intval($row->total);
        }
        else return 0;
	}
	
	function get_paged_list($limit = 10, $offset = 0)
	{
		$this->db->order_by('name','asc');
		return $this->db->get($this->table, $limit, $offset);
	}
	
	function get_by_id($id)
	{
		$this->db->where('id', $id);
		return $this->db->get($this->table);
	} 
    
    function get_by_parent_id($parent_id)
	{
	    if(empty($parent_id)) $this->db->where('parent_id is null');
		else $this->db->where('parent_id', $parent_id);
		return $this->db->get($this->table);
	}
    
    function is_has_child($subnet_id)
    {
        $this->db->select('count(id) as total');
        $this->db->where('parent_id', $subnet_id);
        $rs = $this->db->get($this->table);
        if($rs->num_rows()>0) {
            $row = $rs->row();
            if(intval($row->total) > 0) return true;
            else return false;
        }
        else return false; 
    }
    
    function get_site_by_region($region) {
        if(is_array($region) && count($region) > 0) $this->db->where_in('region_id', $region);
        elseif(!is_array($region) && !empty($region)) $this->db->where('region_id', $region);
        $this->db->order_by('name','asc');
        return $this->db->get('site_view');
    }
    
    function is_has_alarm($subnet_id, $field)
    {
        $this->db->select('count(id) as total');
        $this->db->where($field, $subnet_id);
        $rs = $this->db->get('alarm_temp_view');
        if($rs->num_rows()>0) {
            $row = $rs->row();
            if(intval($row->total) > 0) return true;
            else return false;
        }
        else return false; 
    }
}
?>