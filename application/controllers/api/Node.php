<?php defined('BASEPATH') OR exit('No direct script access allowed');

require APPPATH . '/libraries/REST_Controller.php';

class Node extends REST_Controller 
{	
	function __construct()
	{
		parent::__construct();
		$this->load->model('SubnetModel','',TRUE);
        $this->load->model('NodeModel','',TRUE);
        $this->load->model('LampControlModel','',TRUE);
        
	}
    
    function index()
    {
        print 'site ok';
    }
    
    function all_get()
    {
        $this->response($this->NodeModel->get_all()->result(), REST_Controller::HTTP_OK);
    }
    
    function site_get()
    {
        $subnet_id = $this->uri->segment(4);
        if($subnet_id == '' || $subnet_id == '_') $subnet_id = '';
        else $subnet_id = explode('_', $subnet_id);
        $this->response($this->NodeModel->get_by_site($subnet_id)->result(), REST_Controller::HTTP_OK);        
    }
    
    function get_by_region()
    {
        $region_id = $this->uri->segment(4);
        if(empty($region_id)) print json_encode(array('success'=>false, 'rows'=>array()));
        else print json_encode(array('success'=>true, 'rows'=>$this->SubnetModel->getSiteByRegionId($region_id)->result()));
    }
    
    function child()
    {
        $node_id = $this->uri->segment(4);
        if(empty($node_id)) print json_encode(array('success'=>false, 'rows'=>array()));
        else print json_encode(array('success'=>true, 'rows'=>$this->NodeModel->get_child($node_id)->result()));
    }
    
    function get_node()
    {
        $site_id = $this->uri->segment(4);
        if(empty($site_id)) print json_encode(array('success'=>false, 'rows'=>array()));
        else print json_encode(array('success'=>true, 'rows'=>$this->NodeModel->get_by_subnet_id($site_id)->result()));
    }
    
    function master_get()
    {
        $this->response(array('success'=>true, 'data'=>$this->NodeModel->get_master('')->result()), REST_Controller::HTTP_OK);
    }
    
    function save_post()
    {
        $id = (trim($this->input->post('id')) == '') ? '' : trim($this->input->post('id'));
        $name = (trim($this->input->post('name')) == '') ? '' : trim($this->input->post('name'));
        $phone = (trim($this->input->post('phone')) == '') ? NULL : trim($this->input->post('phone'));
        $latitude = (trim($this->input->post('latitude')) == '') ? '' : trim($this->input->post('latitude'));
        $longitude = (trim($this->input->post('longitude')) == '') ? '' : trim($this->input->post('longitude'));
        $subnet_id = (trim($this->input->post('subnet_id')) == '') ? NULL : trim($this->input->post('subnet_id'));
        $customer_id = (trim($this->input->post('customer_id')) == '') ? NULL : trim($this->input->post('customer_id'));
        
        if(empty($name)) print json_encode(array('success'=>false, 'status'=>200, 'msg'=>'Site name is required.'));
        elseif(empty($phone)) print json_encode(array('success'=>false, 'status'=>200, 'msg'=>'Phone number is required.'));
        elseif(empty($latitude)) print json_encode(array('success'=>false, 'status'=>200, 'msg'=>'Latitude is required.'));
        elseif(empty($longitude)) print json_encode(array('success'=>false, 'status'=>200, 'msg'=>'Longitude is required.'));
        elseif(empty($subnet_id)) print json_encode(array('success'=>false, 'status'=>200, 'msg'=>'Network group is required.'));
        elseif(empty($customer_id)) print json_encode(array('success'=>false, 'status'=>200, 'msg'=>'Customer is required.'));
        else {
            $values = array();
            $values['name'] = $name;
            $values['phone']  = $phone;
            $values['latitude'] = $latitude;
            $values['longitude']= $longitude;
            $values['subnet_id'] = $subnet_id;
            $values['customer_id']= $customer_id;
            
            if($id == '') {
                $values['created_at']   = date('Y-m-d H:i:s');
                $this->db->insert('node', $values);
                $id = $this->db->insert_id();
                $this->response(array('success'=>true, 'msg'=>'Create site successfully.', 'data'=>intval($id)), REST_Controller::HTTP_CREATED);
            }
            else {
                $values['updated_at']   = date('Y-m-d H:i:s');
                $rs = $this->NodeModel->update($id, $values);
                if($rs === FALSE) $this->response(array('success'=>false, 'msg'=>'Update site failed.'), REST_Controller::HTTP_OK); 
                else $this->response(array('success'=>true, 'msg'=>'Update site successfully.'), REST_Controller::HTTP_OK);
            }
        }
    }
    
    function delete_post()
    {
        $site_id    = $this->uri->segment(4);
        if(empty($site_id)) $site_id = $this->input->post('site_id');
        if(empty($site_id)) $this->response(array('success'=>false, 'msg'=>'Site is empty.'), REST_Controller::HTTP_OK);
        else {
            $res = $this->NodeModel->delete($site_id);
            if($res == FALSE) $this->response(array('success'=>false, 'msg'=>'Site delete failed.'), REST_Controller::HTTP_OK);
            else $this->response(array('success'=>true, 'msg'=>'Site delete successfully.'), REST_Controller::HTTP_OK);
        }
    }
    
    function cmd()
    {
        $site_id    = $this->uri->segment(4);
        $command    = trim($this->uri->segment(5));
        
        if(empty($site_id)) $site_id = $this->input->post('site_id');
        if(empty($command)) $command = trim($this->input->post('command'));
        
        if(empty($site_id)) print json_encode(array('success'=>false, 'status'=>200, 'msg'=>'Site is empty.'));
        elseif(empty($command)) print json_encode(array('success'=>false, 'status'=>200, 'msg'=>'Command is empty.'));
        elseif(!in_array(strtoupper($command), array('ON', 'OFF'))) print json_encode(array('success'=>false, 'status'=>200, 'msg'=>'Command is not valid. You have to set ON or OFF.'));
        else {
            $rs = $this->NodeModel->get_by_id($site_id);
            if($rs->num_rows() > 0) {
                $site = $rs->row();
                $imei = '';
                if(trim($site->imei) != '') $imei = trim($site->imei);
                else {
                    $rss = $this->NodeModel->get_by_id($site->consent_id);
                    if($rss->num_rows() > 0) {
                        $sitem = $rss->row();
                        $imei = trim($sitem->imei);
                    }
                    else print json_encode(array('success'=>false, 'status'=>200, 'msg'=>'Site master is not defined for selected site.'));
                    $rss->free_result();
                }
                
                if($imei == '') print json_encode(array('success'=>false, 'status'=>200, 'msg'=>'IMEI is not defined for selected site.'));
                else {
                    $lamp   = strtoupper($site->name);
                    $cmd    = strtoupper($command);
                    $rsc    = $this->LampControlModel->get_by_imei_lamp($imei, $lamp, $cmd);
                    if($rsc->num_rows()>0) print json_encode(array('success'=>false, 'status'=>200, 'msg'=>'Please wait for previous command.'));
                    else {
                        $values = array();
                        $values['imei']         = $imei;
                        $values['site_id']      = $site->id;
                        $values['set_status']   = $cmd;
                        $result = $this->db->insert('lamp_controll', $values);
                    
                        if($result == FALSE) print json_encode(array('success'=>false, 'status'=>200, 'msg'=>'Set Turn '.$command.' was failed.'));
                        else print json_encode(array('success'=>true, 'status'=>200, 'msg'=>'Set Turn '.$command.' was succeed. Please wait some minutes.'));
                    }
                    $rsc->free_result();
                }
            }
            else print json_encode(array('success'=>false, 'status'=>200, 'msg'=>'Site is not registered.'));
            $rs->free_result();
        }
    }
    
    function turn()
    {
        $command    = strtoupper(trim($this->uri->segment(4)));
        if(empty($command)) print json_encode(array('success'=>false, 'status'=>200, 'msg'=>'Command is empty.'));
        elseif(!in_array($command, array('ON','OFF'))) print json_encode(array('success'=>false, 'status'=>200, 'msg'=>'Invalid command. Please use ON or OFF'));
        else {
            
            if($command == 'ON') {
                $rs = $this->NodeModel->get_by_status($subnet_id, '0');
                if($rs->num_rows()>0){
                    $rows  = $rs->result();
                    $lamps = array();
                    $i=0;
                    foreach($rows as $row){
                        $lamps[$i] = $row->id;
                        $i++;
                    }
                    $rss = $this->LampControlModel->get_by_ids_cmd($lamps, $command);
                    if($rss->num_rows() == count($lamps))  print json_encode(array('success'=>false, 'status'=>200, 'msg'=>'All site is waiting to turn ON.'));
                    else {
                        $rows  = $rss->result();                        
                        #remove for already turn ON
                        foreach($rows as $row) {
                            if (($key = array_search($row->id, $lamps)) !== false) {
                                unset($lamps[$key]);
                            }
                        }
                        #print json_encode(array('success'=>true, 'status'=>200, 'msg'=>'All site has been turned ON.'));
                    }
                    $rss->free_result();
                    
                    $rsn    = $this->NodeModel->get_by_ids($lamps)->result();
                    foreach($rsn as $row) {
                        $data   = array();
                        $data['site_id']    = $row->id;
                        $data['imei']       = $row->imei;
                        $data['set_status'] = $command;
                        $this->db->insert('lamp_controll', $data);
                    }
                }
                else print json_encode(array('success'=>false, 'status'=>200, 'msg'=>'All site has been turned ON.'));
                $rs->free_result();
            }
            else {
                $rs = $this->NodeModel->get_by_status($subnet_id, '1');
                if($rs->num_rows()>0){
                    $rows  = $rs->result();
                    $lamps = array();
                    $i=0;
                    foreach($rows as $row){
                        $lamps[$i] = $row->id;
                        $i++;
                    }
                    $rss = $this->LampControlModel->get_by_ids_cmd($lamps, $command);
                    if($rss->num_rows() == count($lamps))  print json_encode(array('success'=>false, 'status'=>200, 'msg'=>'All site is waiting to turn OFF.'));
                    else {
                        $rows  = $rss->result();                    
                        #remove for already turn OFF
                        foreach($rows as $row) {
                            if (($key = array_search($row->id, $lamps)) !== false) {
                                unset($lamps[$key]);
                            }
                        }
                    }
                    $rss->free_result();
                    
                    $rsn    = $this->NodeModel->get_by_ids($lamps)->result();
                    foreach($rsn as $row) {
                        $data   = array();
                        $data['site_id']    = $row->id;
                        $data['imei']       = $row->imei;
                        $data['set_status'] = $command;
                        $this->db->insert('lamp_controll', $data);
                    }
                }
                else print json_encode(array('success'=>false, 'status'=>200, 'msg'=>'All site has been turned OFF.'));
                $rs->free_result();
            }
        }        
    }
    
    function clear()
    {
        $command    = trim($this->uri->segment(4));
        print json_encode(array('success'=>false, 'status'=>200, 'msg'=>'Disabled function.'));
    }
    
    function info_get()
    {
        $node_id = $this->uri->segment(4);
        $row    = $this->NodeModel->get_by_id($node_id)->row();
        $row->total_runhour = $this->NodeModel->get_total_runhour($node_id);
        $this->response($row, REST_Controller::HTTP_OK);
    }
    
    function search_get()
    {
        $search         = $this->input->get('q');
        $customer_id    = $this->session->userdata('customer_id');
        $rows           = $this->NodeModel->search($search, $customer_id)->result();
        $this->response($rows, REST_Controller::HTTP_OK);
    }
}
?>