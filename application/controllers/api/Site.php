<?php
defined('BASEPATH') OR exit('No direct script access allowed');

require APPPATH . '/libraries/REST_Controller.php';

class Site extends REST_Controller 
{	
	function __construct()
	{
		parent::__construct();
        $this->load->model('SiteModel','',TRUE);
	}
    
    function all_get()
    {
        $this->response($this->SiteModel->get_list()->result(), REST_Controller::HTTP_OK);
    }    
    
    function region_get()
    {
        $region_id = explode('_', $this->uri->segment(4));
        $this->response($this->SiteModel->get_by_region($region_id)->result(), REST_Controller::HTTP_OK);
    }
    
    function fetch_get()
    {
        $page    = $this->uri->segment(4);
        $size    = $this->uri->segment(5);
        if(empty($page) || $page == '0') $page = 1;
        if(empty($size) || $size == '0') $size = 10;
        $offset  = ($page-1)*$size;
        
        $rows   = $this->SiteModel->get_paged_list($size, $offset)->result();
        $total  = $this->SiteModel->count_all();
        $totalPage  = ceil($total/$size);
        $firstPage  = ($page == 0 || $page == 1) ? true : false;
        $lastPage   = ($page == $totalPage) ? true : false;
        $msg        = array('content'=>$rows, 'totalPage'=>$totalPage, 'firstPage'=>$firstPage, 'lastPage'=>$lastPage, 'page'=>intval($page), 'total'=>$total);
        $this->response($msg, REST_Controller::HTTP_OK);
    }
    
    function save_post()
    {
        $values = json_decode(file_get_contents('php://input'), true);
        unset($values['region']);
        unset($values['customer']);
        $id     = $this->SiteModel->save($values);
        $values['id']   = $id;
        $this->response($values, REST_Controller::HTTP_CREATED);
    }
    
    function update_post()
    {
        $id    = $this->uri->segment(4);
        $values = json_decode(file_get_contents('php://input'), true);
        if(isset($values['region'])) unset($values['region']);
        if(isset($values['customer'])) unset($values['customer']);
        $this->SiteModel->update($id, $values);
        $this->response($values, REST_Controller::HTTP_OK);
    }
    
    function remove_delete()
    {
        $id    = $this->uri->segment(4);
        $this->SiteModel->delete($id);
        $this->response(array('succeed'=>true), REST_Controller::HTTP_OK);
    }
}
?>