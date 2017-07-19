<?php
defined('BASEPATH') OR exit('No direct script access allowed');

require APPPATH . '/libraries/REST_Controller.php';

class Config extends REST_Controller 
{	
	function __construct()
	{
		parent::__construct();
		$this->load->model('ConfigModel','',TRUE);
	}
    
    function list_get()
    {
        $this->response($this->ConfigModel->get_by_id('1')->row(), REST_Controller::HTTP_OK);
    }
    
    function save_post()
    {
        $values = json_decode(file_get_contents('php://input'), true);
        $id     = $this->ConfigModel->save($values);
        $values['id']   = $id;
        $this->response($values, REST_Controller::HTTP_CREATED);
    }
    
    function update_post()
    {
        $values = json_decode(file_get_contents('php://input'), true);
        $this->ConfigModel->update($values['id'], $values);
        $this->response($values, REST_Controller::HTTP_OK);
    }
}
?>