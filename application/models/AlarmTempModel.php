<?php
class AlarmTempModel extends CI_Model 
{
	public $table	= 'alarm_temp';

	function __construct()
	{
		parent::__construct();
	}
	
    function get_total($node_id)
    {
        $this->db->select('count(id) as total');
        $this->db->where('node_id', $node_id);
        $rs = $this->db->get($this->table);
        if($rs->num_rows() > 0) {
            $row = $rs->row();
            return intval($row->total);
        }
        else return 0;
    }
    
    function get_paged_list($node_id, $limit, $offset, $sort, $order)
    {
        $this->db->where('node_id', $node_id);
        $this->db->order_by($sort, $order);
        return $this->db->get($this->table.'_view', $limit, $offset);
    }
    
    function get_list($node_id)
    {
        if(!empty($node_id)) $this->db->where('node_id', $node_id);
        $this->db->order_by('dtime', 'desc');
        return $this->db->get($this->table.'_view');      
    }
    
    function get_total_model($model, $model_id, $alarm_id, $from, $to, $acknowledge='0')
    {
        $this->db->select('count(id) as total');
        if($model == 'node' && $model_id != '_') $this->db->where_in('node_id', explode('_', $model_id));
        elseif($model == 'site' && $model_id != '_') $this->db->where_in('subnet_id', explode('_', $model_id));
        elseif($model == 'region' && $model_id != '_') $this->db->where_in('region_id', explode('_', $model_id));
        
        if($alarm_id != '' && $alarm_id != '_') $this->db->where_in('alarm_list_id', explode('_', $alarm_id));        
        if($from != '' && $from != '_') $this->db->where('dtime >=', $from);
        if($to != '' && $to != '_') $this->db->where('dtime <=', $to);
        if($acknowledge != '' && $acknowledge != '_') $this->db->where('acknowledge', $acknowledge);
        
        $rs = $this->db->get($this->table.'_view');
        if($rs->num_rows() > 0) {
            $row = $rs->row();
            return intval($row->total);
        }
        else return 0;
    }
    
    function get_paged_model($model, $model_id, $alarm_id, $from, $to, $acknowledge='0', $limit, $offset, $sort, $order)
    {
        if($model == 'site' && $model_id != '_') $this->db->where_in('node_id', explode('_', $model_id));
        elseif($model == 'area' && $model_id != '_') $this->db->where_in('subnet_id', explode('_', $model_id));
        elseif($model == 'region' && $model_id != '_') $this->db->where_in('region_id', explode('_', $model_id));
        
        if($alarm_id != '' && $alarm_id != '_') $this->db->where_in('alarm_list_id', explode('_', $alarm_id));        
        if($from != '' && $from != '_') $this->db->where('dtime >=', $from.' 00:00:00');
        if($to != '' && $to != '_') $this->db->where('dtime <=', $to.' 23:59:59');
        if($acknowledge != '' && $acknowledge != '_') $this->db->where('acknowledge', $acknowledge);
        
        $this->db->order_by($sort, $order);
        return $this->db->get($this->table.'_view', $limit, $offset);
    }
    
    function get_statistic()
    {
        $this->db->select('als.name,als.color,count(al.id) as total');
        $this->db->from('severity als ');
        $this->db->join('alarm_temp al', 'als.id=al.severity_id', 'left');
        $this->db->group_by('als.name,als.color');
        return $this->db->get();
    }
    
    function get_total_active($customer_id, $acknowledge='0')
    {
        $this->db->select('count(al.id) as total');
        $this->db->join('node n', 'al.node_id=n.id');
        if($acknowledge != '' && $acknowledge != '_') $this->db->where('al.acknowledge', $acknowledge);
        if($customer_id != '' && $customer_id != 'null') $this->db->where('n.customer_id', $customer_id);
        $rs = $this->db->get($this->table.' al');
        if($rs->num_rows() > 0) {
            $row = $rs->row();
            return intval($row->total);
        }
        else return 0;
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