<?php
class NodeModel extends CI_Model 
{

	public $table	= 'node';

	function __construct()
	{
		parent::__construct();
	}
	
    function get_total($status=1)
	{
	    $this->db->select('count(id) as total');
        if($status) $this->db->where('updated_at is not null');
        $rs = $this->db->get($this->table);
        if($rs->num_rows()>0) {
            $row = $rs->row();
            return intval($row->total);
        }
        else return 0;
	}
    
    function get_all()
	{
	    $this->db->select('s.*, op.name as status, sub.name as subnet');
        $this->db->join('subnet sub', 's.subnet_id=sub.id');
        $this->db->join('opr_status op', 's.opr_status_id=op.id');
		$this->db->order_by('s.name', 'asc');
		return $this->db->get($this->table.' s');
	}
    
	function get_by_id($id)
	{
	    $this->db->select('s.*, sub.name as subnet');
        $this->db->join('subnet sub', 's.subnet_id=sub.id');
		$this->db->where('s.id', $id);
		return $this->db->get($this->table.' s');
	}
    
    function get_by_ids($ids)
	{
	    $this->db->select('id,name,phone');
		$this->db->where_in('id', $ids);
		return $this->db->get($this->table);
	}
    
    function get_by_site($sites)
	{
	    $this->db->select('id,name,phone');
	    if(is_array($sites) && count($sites) > 0) $this->db->where_in('subnet_id', $sites);
        elseif(!is_array($sites) && !empty($sites)) $this->db->where('subnet_id', $sites);
        $this->db->order_by('name','asc');
        return $this->db->get($this->table);
	}
    
    function get_master($subnet_id)
	{
	    $this->db->select('id,name,phone');
		if(!empty($subnet_id)) $this->db->where('subnet_id', $subnet_id);
		return $this->db->get($this->table);
	}
    
    function get_childs($node_id)
    {
        $this->db->select('id');
        $this->db->where('consent_id', $node_id);
        $this->db->order_by('id', 'asc');
        $rs  = $this->db->get($this->table);
        $rows= $rs->result();
        
        $ids = array();
        $i   = 0;
        foreach($rows as $row)
        {
            $ids[$i] = $row->id;
            $i++;
        }
        $rs->free_result();
        return $ids;
    }
    
    function get_child($node_id)
	{
	    $this->db->select('id,name,pvoltage,vbatt,ibatt,iload,temperature_ctrl,temperature_batt,status,updated_at');
        $this->db->where_in('id', array_merge(array($node_id), $this->get_childs($node_id)));
		return $this->db->get($this->table);
	}
    
    function get_by_status($subnet_id, $status)
	{
	    $this->db->select('id,name,phone');
		if(!empty($subnet_id)) $this->db->where('subnet_id', $subnet_id);
        $this->db->where('status', $status);
		return $this->db->get($this->table);
	}
    
    function get_by_phone($phone)
	{
		if(!empty($phone)) $this->db->where('phone', $phone);
		return $this->db->get($this->table);
	}
    
    function get_by_subnet_id($subnet_id) {
        $this->db->select('id,name,phone');
        if(is_array($subnet_id) && count($subnet_id)>0) $this->db->where_in('subnet_id', $subnet_id);
	    elseif(!is_array($subnet_id) && $subnet_id != '') $this->db->where('subnet_id', $subnet_id);
        $this->db->order_by('name', 'asc');
		return $this->db->get($this->table);
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
    
    function get_total_runhour($node_id)
    {
        $this->db->select('run_hour as total');
        $this->db->where('id', $node_id);
        $rs = $this->db->get($this->table);
        if($rs->num_rows()>0) {
            $row = $rs->row();
            return floatval($row->total);
        }
        else return 0;
    }
    
    function search($search, $customer_id)
    {
        $this->db->select('id,name,phone');
        if($customer_id != '') $this->db->where('customer_id', $customer_id);
        $this->db->like('lower(name)', strtolower($search));
        $this->db->order_by('name', 'asc');
        return $this->db->get($this->table);
    }
    
    function is_has_alarm($node_id, $field)
    {
        $this->db->select('count(id) as total');
        $this->db->where($field, $node_id);
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