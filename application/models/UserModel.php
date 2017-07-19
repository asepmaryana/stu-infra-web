<?php
class UserModel extends CI_Model 
{
	public $table	= 'users';

	function __construct()
	{
		parent::__construct();
	}
	
	function count_all()
	{
	    $this->db->where('role_id not in(1)');
		return $this->db->count_all($this->table);
	}
	
	function get_paged_list($limit = 10, $offset = 0)
	{
		$this->db->select("users.*, role.name as role_name, c.name as customer");
		$this->db->join('role', 'users.role_id=role.id', 'left');
        $this->db->join('customer c', 'users.customer_id=c.id', 'left');
        $this->db->where('role_id not in(1)');
		$this->db->order_by('users.id','desc');
		return $this->db->get($this->table, $limit, $offset);
	}

	function get_by_id($id)
	{
	    $this->db->select('u.*, role.name as role_name');
        $this->db->join('role', 'u.role_id=role.id', 'left');
		$this->db->where('u.id', $id);
		return $this->db->get($this->table.' u');
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
                'name'      => $row->name,
                'role_id'	=> $row->role_id,
                'customer_id'	=> $row->customer_id
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