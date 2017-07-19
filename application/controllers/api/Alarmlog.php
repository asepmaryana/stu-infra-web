<?php
defined('BASEPATH') OR exit('No direct script access allowed');

require APPPATH . '/libraries/REST_Controller.php';

class Alarmlog extends REST_Controller 
{	
	function __construct()
	{
		parent::__construct();
		$this->load->model('AlarmlogModel','',TRUE);
	}
    
    function index_get()
    {
        print 'datalog ok';
    }
    
    function site_get()
    {
        $site_id    = $this->uri->segment(4);
        $from       = $this->uri->segment(5);
        $to         = $this->uri->segment(6);
        $doc        = $this->uri->segment(7);
        
        $rows       = $this->AlarmlogModel->get_site_and_date($site_id, $from, $to)->result();
        
        if($doc == 'json') $this->response($rows, REST_Controller::HTTP_OK);
        elseif($doc == 'xls')
        {
            require_once APPPATH . 'third_party/phpexcel/PHPExcel.php';
            
            $objPHPExcel    = new PHPExcel();
            $r = 1;
            $objPHPExcel->getActiveSheet()->setCellValue('A'.$r, 'Regional');
            $objPHPExcel->getActiveSheet()->setCellValue('B'.$r, 'Area');
            $objPHPExcel->getActiveSheet()->setCellValue('C'.$r, 'Site');
            $objPHPExcel->getActiveSheet()->setCellValue('D'.$r, 'Start');
            $objPHPExcel->getActiveSheet()->setCellValue('E'.$r, 'Stop');
            $objPHPExcel->getActiveSheet()->setCellValue('F'.$r, 'Severity');
            $objPHPExcel->getActiveSheet()->setCellValue('G'.$r, 'Alarm Name');
            
            foreach($rows as $row)
            {
                $r++;
                $objPHPExcel->getActiveSheet()->setCellValue('A'.$r, $row->region);
                $objPHPExcel->getActiveSheet()->setCellValue('B'.$r, $row->area);
                $objPHPExcel->getActiveSheet()->setCellValue('C'.$r, $row->site);
                $objPHPExcel->getActiveSheet()->setCellValue('D'.$r, $row->ddtime);
                $objPHPExcel->getActiveSheet()->setCellValue('E'.$r, $row->ddtime_end);
                $objPHPExcel->getActiveSheet()->setCellValue('F'.$r, $row->severity);
                $objPHPExcel->getActiveSheet()->setCellValue('G'.$r, $row->alarm_label);
            }
            foreach(range('A','G') as $columnID) { $objPHPExcel->getActiveSheet()->getColumnDimension($columnID)->setAutoSize(true); }
            $this->load->helper('excel');
            download_excel($objPHPExcel, 'Alarmlog Report');
        }
    }
    
    function fetch_get()
    {
        $mode       = $this->uri->segment(4);
        $site_id    = $this->uri->segment(5);
        $alarm_id   = $this->uri->segment(6);
        $from       = $this->uri->segment(7);
        $to         = $this->uri->segment(8);
        $doc        = $this->uri->segment(9);
        
        $site_id    = ($site_id == '_') ? array() : explode('_', $site_id);
        $alarm_id   = ($alarm_id == '_') ? array() : explode('_', $alarm_id);
        
        $rows       = $this->AlarmlogModel->get_site_alarm_and_date($site_id, $alarm_id, $from, $to)->result();
        
        if($doc == 'json') $this->response($rows, REST_Controller::HTTP_OK);
        elseif($doc == 'xls')
        {
            require_once APPPATH . 'third_party/phpexcel/PHPExcel.php';
            
            $objPHPExcel    = new PHPExcel();
            $r = 1;
            $objPHPExcel->getActiveSheet()->setCellValue('A'.$r, 'Regional');
            $objPHPExcel->getActiveSheet()->setCellValue('B'.$r, 'Area');
            $objPHPExcel->getActiveSheet()->setCellValue('C'.$r, 'Site');
            $objPHPExcel->getActiveSheet()->setCellValue('D'.$r, 'Start');
            $objPHPExcel->getActiveSheet()->setCellValue('E'.$r, 'Stop');
            $objPHPExcel->getActiveSheet()->setCellValue('F'.$r, 'Severity');
            $objPHPExcel->getActiveSheet()->setCellValue('G'.$r, 'Alarm Name');
            
            foreach($rows as $row)
            {
                $r++;
                $objPHPExcel->getActiveSheet()->setCellValue('A'.$r, $row->region);
                $objPHPExcel->getActiveSheet()->setCellValue('B'.$r, $row->area);
                $objPHPExcel->getActiveSheet()->setCellValue('C'.$r, $row->site);
                $objPHPExcel->getActiveSheet()->setCellValue('D'.$r, $row->ddtime);
                $objPHPExcel->getActiveSheet()->setCellValue('E'.$r, $row->ddtime_end);
                $objPHPExcel->getActiveSheet()->setCellValue('F'.$r, $row->severity);
                $objPHPExcel->getActiveSheet()->setCellValue('G'.$r, $row->alarm_label);
            }
            foreach(range('A','G') as $columnID) { $objPHPExcel->getActiveSheet()->getColumnDimension($columnID)->setAutoSize(true); }
            $this->load->helper('excel');
            download_excel($objPHPExcel, 'Alarmlog Report');
        }
    }
}
?>