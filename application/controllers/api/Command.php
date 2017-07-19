<?php
defined('BASEPATH') OR exit('No direct script access allowed');

require APPPATH . '/libraries/REST_Controller.php';

class Command extends REST_Controller 
{	
	function __construct()
	{
		parent::__construct();
		$this->load->model('CommandModel','',TRUE);
	}
    
    function list_get()
    {
        $commands   = $this->CommandModel->get_list()->result();
		$this->response($commands, REST_Controller::HTTP_OK);
    }
    
    function fetch_get()
    {
        $page    = $this->uri->segment(4);
        $size    = $this->uri->segment(5);
        if(empty($page) || $page == '0') $page = 1;
        if(empty($size) || $size == '0') $size = 10;
        $offset  = ($page-1)*$size;
        
        $rows   = $this->CommandModel->get_paged_list($size, $offset)->result();
        $total  = $this->CommandModel->count_all();
        $totalPage  = ceil($total/$size);
        $firstPage  = ($page == 0 || $page == 1) ? true : false;
        $lastPage   = ($page == $totalPage) ? true : false;
        $msg        = array('content'=>$rows, 'totalPage'=>$totalPage, 'firstPage'=>$firstPage, 'lastPage'=>$lastPage, 'page'=>intval($page), 'total'=>$total);
        $this->response($msg, REST_Controller::HTTP_OK);
    }
    
    function save_post()
    {
        $values = json_decode(file_get_contents('php://input'), true);
        $id     = $this->CommandModel->save($values);
        $values['id']   = $id;
        $this->response($values, REST_Controller::HTTP_CREATED);
    }
    
    function update_post()
    {
        $id    = $this->uri->segment(4);
        $values = json_decode(file_get_contents('php://input'), true);
        $this->CommandModel->update($id, $values);
        $this->response($values, REST_Controller::HTTP_OK);
    }
    
    function remove_delete()
    {
        $id    = $this->uri->segment(4);
        $this->CommandModel->delete($id);
        $this->response(array('succeed'=>true), REST_Controller::HTTP_OK);
    }
}
?>