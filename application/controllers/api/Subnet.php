<?php
defined('BASEPATH') OR exit('No direct script access allowed');

require APPPATH . '/libraries/REST_Controller.php';

class Subnet extends REST_Controller 
{	
	function __construct()
	{
		parent::__construct();
		
		$this->load->model('SubnetModel','',TRUE);
        $this->load->model('NodeModel','',TRUE);
	}
    
    function index_get()
    {
        print 'subnet ok';
    }
    
    function all_get()
    {
        $this->response($this->SubnetModel->get_sites()->result(), REST_Controller::HTTP_OK);
    }
    
    function region_get()
    {
        $this->response($this->SubnetModel->get_regions()->result(), REST_Controller::HTTP_OK);
    }
    
    function area_get()
    {
        $regions_id = explode('_', $this->uri->segment(4));
        $this->response($this->SubnetModel->get_areas($regions_id)->result(), REST_Controller::HTTP_OK);
    }
    
    function site_get()
    {
        $area_id = explode('_', $this->uri->segment(4));
        $this->response($this->NodeModel->get_by_subnet_id($area_id)->result(), REST_Controller::HTTP_OK);
    }
    
    function statistic_get()
    {
        $total_site = $this->SubnetModel->get_total_site();
        $total_node = $this->NodeModel->get_total(0);
        $total_node_active = $this->NodeModel->get_total(1);
        
        $msg    = array(
            array('label'=>'Site', 'value'=>$total_site),
            array('label'=>'Node', 'value'=>$total_node),
            array('label'=>'Up', 'value'=>$total_node_active),
            array('label'=>'Lost', 'value'=>($total_node - $total_node_active))
        );
        $this->response($msg, REST_Controller::HTTP_OK);
    }
    
    function get_by_region()
    {
        $region_id = $this->uri->segment(4);
        if(empty($region_id)) print json_encode(array('success'=>false, 'rows'=>array()));
        else print json_encode(array('success'=>true, 'rows'=>$this->SubnetModel->getSiteByRegionId($region_id)->result()));
    }
    
    function get_node()
    {
        $site_id = $this->uri->segment(4);
        if(empty($site_id)) print json_encode(array('success'=>false, 'rows'=>array()));
        else print json_encode(array('success'=>true, 'rows'=>$this->NodeModel->get_by_subnet_id($site_id)->result()));
    }
    
    function tree()
    {
        $parent_id  = urldecode(trim($this->input->get('id')));
        if($parent_id == '#') $parent_id = '';
        $rows   = $this->SubnetModel->get_by_parent_id($parent_id)->result();
        $data   = array();
        $i=0;
        foreach($rows as $row)
        {
            $children   = $this->SubnetModel->is_has_child($row->id);
            if($children == false) {
                $rsl    = $this->NodeModel->get_master($row->id);
                if($rsl->num_rows()>0) $children = true;
                $rsl->free_result();
            }
            $data[$i]   = array('id'=>$row->id, 'text'=>$row->name, 'state'=>array('opened'=>false), 'children'=>$children);
            $i++;
        }
        
        if(count($rows)==0 && $parent_id != '') {
            $rsl    = $this->NodeModel->get_master($parent_id);
            if($rsl->num_rows()>0) {
                $row    = $rsl->row();
                $data[] = array('id'=>$parent_id.'_'.$row->id, 'text'=>$row->name, 'children'=>false, 'icon'=>'fa fa-circle');
            }
            $rsl->free_result();
        }
        
        header('Content-Type: application/json; charset=utf-8');
        print json_encode($data);
    }
}
?>