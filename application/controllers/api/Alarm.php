<?php
defined('BASEPATH') OR exit('No direct script access allowed');

require APPPATH . '/libraries/REST_Controller.php';

class Alarm extends REST_Controller 
{	
	function __construct()
	{
		parent::__construct();
		#$this->load->model('SubnetModel','',TRUE);
        #$this->load->model('NodeModel','',TRUE);
        $this->load->model('AlarmTempModel','',TRUE);
	}
    
    function index_get()
    {
        //print 'alarm ok';
        $node_id = $this->uri->segment(4);
        $page    = $this->uri->segment(5);
        $size    = $this->uri->segment(6);
        $rows    = $this->AlarmTempModel->get_list($node_id)->result();
        $this->response(array('data'=>$rows, 'total'=>count($rows)), REST_Controller::HTTP_OK);
    }
    
    function total_get()
    {
        $uid            = $this->session->userdata('uid');
        $role_id        = $this->session->userdata('role_id');
        $customer_id    = $this->session->userdata('customer_id');
        
        $total          = $this->AlarmTempModel->get_total_active($customer_id, '0');
        $this->response($total, REST_Controller::HTTP_OK);
    }
    
    function node_get()
    {
        #$node_id = $this->uri->segment(4);
        #$this->response($this->AlarmTempModel->get_list($node_id)->result(), REST_Controller::HTTP_OK);
        $node_id = $this->uri->segment(4);
        $page    = $this->uri->segment(5);
        $size    = $this->uri->segment(6);
        if(empty($page) || $page == '0') $page = 1;
        if(empty($size) || $size == '0') $size = 10;
        $offset  = ($page-1)*$size;
                
        $rows   = $this->AlarmTempModel->get_paged_list($node_id, $size, $offset, 'dtime', 'desc')->result();
        $total  = $this->AlarmTempModel->get_total($node_id);
        $totalPage  = ceil($total/$size);
        $firstPage  = ($page == 0 || $page == 1) ? true : false;
        $lastPage   = ($page == $totalPage) ? true : false;
        $msg        = array('content'=>$rows, 'totalPage'=>$totalPage, 'firstPage'=>$firstPage, 'lastPage'=>$lastPage, 'page'=>intval($page), 'total'=>$total);
        $this->response($msg, REST_Controller::HTTP_OK);
    }
    
    function fetch_get()
    {
        $model      = $this->uri->segment(4);
        $model_id   = $this->uri->segment(5);
        $alarm_id   = $this->uri->segment(6);
        $from       = $this->uri->segment(7);
        $to         = $this->uri->segment(8);
        $page       = $this->uri->segment(9);
        $size       = $this->uri->segment(10);
        $ack        = $this->uri->segment(11);
        $doc        = $this->uri->segment(12);
        
        if(empty($page) || $page == '0') $page = 1;
        if(empty($size) || $size == '0') $size = 10;
        if($ack == '_') $ack = '';
        $offset  = ($page-1)*$size;
        
        $rows   = $this->AlarmTempModel->get_paged_model($model, $model_id, $alarm_id, $from, $to, $ack, $size, $offset, 'dtime', 'desc')->result();
        $total  = $this->AlarmTempModel->get_total_model($model, $model_id, $alarm_id, $from, $to, $ack);
        $totalPage  = ceil($total/$size);
        $firstPage  = ($page == 0 || $page == 1) ? true : false;
        $lastPage   = ($page == $totalPage) ? true : false;
        $msg        = array('content'=>$rows, 'totalPage'=>$totalPage, 'firstPage'=>$firstPage, 'lastPage'=>$lastPage, 'page'=>intval($page), 'total'=>$total);
        
        if($doc == 'xls')
        {
            require_once APPPATH . 'third_party/phpexcel/PHPExcel.php';
            
            $objPHPExcel    = new PHPExcel();
            $r = 1;
            $objPHPExcel->getActiveSheet()->setCellValue('A'.$r, 'Regional');
            $objPHPExcel->getActiveSheet()->setCellValue('B'.$r, 'Area');
            $objPHPExcel->getActiveSheet()->setCellValue('C'.$r, 'Site');
            $objPHPExcel->getActiveSheet()->setCellValue('D'.$r, 'Date Time');
            $objPHPExcel->getActiveSheet()->setCellValue('E'.$r, 'Severity');
            $objPHPExcel->getActiveSheet()->setCellValue('F'.$r, 'Alarm Name');
            
            foreach($rows as $row)
            {
                $r++;
                $objPHPExcel->getActiveSheet()->setCellValue('A'.$r, $row->region);
                $objPHPExcel->getActiveSheet()->setCellValue('B'.$r, $row->area);
                $objPHPExcel->getActiveSheet()->setCellValue('C'.$r, $row->site);
                $objPHPExcel->getActiveSheet()->setCellValue('D'.$r, $row->ddtime);
                $objPHPExcel->getActiveSheet()->setCellValue('E'.$r, $row->severity);
                $objPHPExcel->getActiveSheet()->setCellValue('F'.$r, $row->alarm_label);
            }
            
            $this->load->helper('excel');
            download_excel($objPHPExcel, 'Alarm Active');
        }
        else $this->response($msg, REST_Controller::HTTP_OK);
    }
    
    function statistic_get()
    {
        $this->response($this->AlarmTempModel->get_statistic()->result(), REST_Controller::HTTP_OK);
    }
    
    function ack_post()
    {
        $rows = json_decode(file_get_contents('php://input'), true);
        $i=0;
        foreach($rows as $row)
        {
            if($row['selected'])
            {
                $values = array();
                $values['acknowledge']  = '1';
                $this->AlarmTempModel->update($row['id'], $values);
                $rows[$i]['acknowledge'] = '1';
            }
            $i++;
        }
        $this->response($rows, REST_Controller::HTTP_OK);
    }
    
    function delete_post()
    {
        $rows = json_decode(file_get_contents('php://input'), true);
        $i=0;
        foreach($rows as $row)
        {
            if($row['selected']) $this->AlarmTempModel->delete($row['id']);
            $i++;
        }
        $this->response($rows, REST_Controller::HTTP_OK);
    }
}
?>