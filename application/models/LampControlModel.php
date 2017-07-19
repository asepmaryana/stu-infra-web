<?php
class LampControlModel extends CI_Model 
{
	public $table	= 'lamp_controll';

	function __construct()
	{
		parent::__construct();
	}
	
    function get_by_imei($imei)
    {
        $this->db->select('s.name,l.set_status');
        $this->db->join('site s', 'l.site_id=s.id');
        $this->db->where('l.imei', $imei);
        $this->db->order_by('l.id','asc');
        return $this->db->get($this->table.' l', '1', '0');
    }
    
    function get_by_imei_lamp($imei, $lamp, $cmd)
    {
        $this->db->select('l.id,l.site_id');
        $this->db->join('site s', 'l.site_id=s.id');
        $this->db->where('l.imei', $imei);
        $this->db->where('s.name', $lamp);
        $this->db->where('l.set_status', $cmd);
        $this->db->order_by('l.id','asc');
        return $this->db->get($this->table.' l', '1', '0');
    }
    
	function count_all()
	{
		return $this->db->count_all($this->table);
	}
	
	function get_paged_list($limit = 10, $offset = 0)
	{
		$this->db->select("users.*, user_level.name as levelname");
		$this->db->join('level', 'users.level_id=level.id', 'left');
		$this->db->order_by('id','desc');
		return $this->db->get($this->table, $limit, $offset);
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
		$this->db->update($this->table, $data);
	}
	
	function delete($id)
	{
		$this->db->where('id', $id);
		$this->db->delete($this->table);
	}
	
	function authenticate($username, $password)
	{
	    $this->db->where('username', $username);
        $this->db->where('password', $password);
        $query = $this->db->get($this->table);
		if($query->num_rows() > 0) {
			$row 	= $query->row();
			$info 	= array(
                'uid'       => $row->id,
                'username'  => $row->username,
                'roles_id'	=> $row->roles_id,
                'customers_id'	=> $row->customers_id
            );
			$this->session->set_userdata($info);
			return true;
		}
        else return false;
	}
	
	function lists($opid=0)
	{
		if($opid != 1) $this->db->where('roles_id', $opid);
		return $this->db->get($this->table);
	}
}
?>