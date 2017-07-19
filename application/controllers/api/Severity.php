<?php
defined('BASEPATH') OR exit('No direct script access allowed');

require APPPATH . '/libraries/REST_Controller.php';

class Severity extends REST_Controller 
{	
	function __construct()
	{
		parent::__construct();
		$this->load->model('SeverityModel','',TRUE);
	}
    
    function all_get()
    {
        $this->response($this->SeverityModel->get_all()->result(), REST_Controller::HTTP_OK);
    }
    
    function fetch_get()
    {
        $page    = $this->uri->segment(4);
        $size    = $this->uri->segment(5);
        if(empty($page) || $page == '0') $page = 1;
        if(empty($size) || $size == '0') $size = 10;
        $offset  = ($page-1)*$size;
        
        $rows   = $this->SeverityModel->get_paged_list($size, $offset)->result();
        $total  = $this->SeverityModel->count_all();
        $totalPage  = ceil($total/$size);
        $firstPage  = ($page == 0 || $page == 1) ? true : false;
        $lastPage   = ($page == $totalPage) ? true : false;
        $msg        = array('content'=>$rows, 'totalPage'=>$totalPage, 'firstPage'=>$firstPage, 'lastPage'=>$lastPage, 'page'=>intval($page), 'total'=>$total);
        $this->response($msg, REST_Controller::HTTP_OK);
    }
    
    function save_post()
    {
        $values = json_decode(file_get_contents('php://input'), true);
        $id     = $this->SeverityModel->save($values);
        $values['id']   = $id;
        $this->response($values, REST_Controller::HTTP_CREATED);
    }
    
    function update_post()
    {
        $id    = $this->uri->segment(4);
        $values = json_decode(file_get_contents('php://input'), true);
        $this->SeverityModel->update($id, $values);
        $this->response(array('succeed'=>true), REST_Controller::HTTP_OK);
    }
    
    function remove_delete()
    {
        $id    = $this->uri->segment(4);
        $this->SeverityModel->delete($id);
        $this->response(array('succeed'=>true), REST_Controller::HTTP_OK);
    }
}
?>