<?php
defined('BASEPATH') OR exit('No direct script access allowed');

require APPPATH . '/libraries/REST_Controller.php';

class Datalog extends REST_Controller 
{	
	function __construct()
	{
		parent::__construct();
		$this->load->model('DatalogModel','',TRUE);
	}
    
    function index()
    {
        print 'datalog ok';
    }
    
    function site_get()
    {
        $site_id    = $this->uri->segment(4);
        $from       = $this->uri->segment(5);
        $to         = $this->uri->segment(6);
        $doc        = $this->uri->segment(7);
        $rows       = $this->DatalogModel->get_site_and_date($site_id, $from, $to)->result();
        
        if($doc == 'xls')
        {
            require_once APPPATH . 'third_party/phpexcel/PHPExcel.php';
            
            $objPHPExcel    = new PHPExcel();
            $r = 1;
            $objPHPExcel->getActiveSheet()->setCellValue('A'.$r, 'Date Time');
            $objPHPExcel->getActiveSheet()->setCellValue('B'.$r, 'Genset Voltage');
            $objPHPExcel->getActiveSheet()->setCellValue('E'.$r, 'Battery Voltage');
            $objPHPExcel->getActiveSheet()->setCellValue('F'.$r, 'Genset Batt Volt');
            $objPHPExcel->getActiveSheet()->setCellValue('G'.$r, 'Status');
            $objPHPExcel->getActiveSheet()->setCellValue('J'.$r, 'Run Hour');
            
            $r++;
            $objPHPExcel->getActiveSheet()->setCellValue('B'.$r, 'R');
            $objPHPExcel->getActiveSheet()->setCellValue('C'.$r, 'S');
            $objPHPExcel->getActiveSheet()->setCellValue('D'.$r, 'T');
            $objPHPExcel->getActiveSheet()->setCellValue('G'.$r, 'Genset');
            $objPHPExcel->getActiveSheet()->setCellValue('H'.$r, 'Rect');
            $objPHPExcel->getActiveSheet()->setCellValue('I'.$r, 'Maint');
            
            foreach($rows as $row)
            {
                $r++;
                #$objPHPExcel->getActiveSheet()->setCellValue('A'.$r, $row->ddtime);
                $dateTimeValue = PHPExcel_Shared_Date::PHPToExcel( strtotime($row->dtime) );
                $objPHPExcel->getActiveSheet()->setCellValue('A'.$r, $dateTimeValue);
                $objPHPExcel->getActiveSheet()->getStyle('A'.$r)->getNumberFormat()->setFormatCode(PHPExcel_Style_NumberFormat::FORMAT_DATE_DATETIME);
                #$objPHPExcel->getActiveSheet()->setCellValue('A'.$r, date('n/j/Y H:i:s', strtotime($row->dtime)));
                $objPHPExcel->getActiveSheet()->setCellValue('B'.$r, $row->genset_vr);
                $objPHPExcel->getActiveSheet()->setCellValue('C'.$r, $row->genset_vs);
                $objPHPExcel->getActiveSheet()->setCellValue('D'.$r, $row->genset_vt);
                $objPHPExcel->getActiveSheet()->setCellValue('E'.$r, $row->batt_volt);
                $objPHPExcel->getActiveSheet()->setCellValue('F'.$r, $row->genset_batt_volt);
                $objPHPExcel->getActiveSheet()->setCellValue('G'.$r, $row->genset_status);
                $objPHPExcel->getActiveSheet()->setCellValue('H'.$r, $row->recti_status);
                $objPHPExcel->getActiveSheet()->setCellValue('I'.$r, $row->maintain_status);
                $objPHPExcel->getActiveSheet()->setCellValue('J'.$r, $row->run_hour);
            }
            
            foreach(range('A','J') as $columnID) { $objPHPExcel->getActiveSheet()->getColumnDimension($columnID)->setAutoSize(true); }
            
            $this->load->helper('excel');
            download_excel($objPHPExcel, 'Datalog Report_'.$from.'-'.$to);
        }
        else $this->response($rows, REST_Controller::HTTP_OK);
    }
    
    function fetch_get()
    {
        $mode       = $this->uri->segment(4);
        $site_id    = $this->uri->segment(5);
        $from       = $this->uri->segment(6);
        $to         = $this->uri->segment(7);
        $doc        = $this->uri->segment(8);
        
        $site_id    = ($site_id == '_') ? array() : explode('_', $site_id);
        
        $rows       = $this->DatalogModel->get_site_and_date($site_id, $from, $to)->result();
        
        if($doc == 'xls')
        {
            require_once APPPATH . 'third_party/phpexcel/PHPExcel.php';
            
            $objPHPExcel    = new PHPExcel();
            $r = 1;
            $objPHPExcel->getActiveSheet()->setCellValue('A'.$r, 'Date Time');
            $objPHPExcel->getActiveSheet()->setCellValue('B'.$r, 'Genset Voltage');
            $objPHPExcel->getActiveSheet()->setCellValue('E'.$r, 'Battery Voltage');
            $objPHPExcel->getActiveSheet()->setCellValue('F'.$r, 'Genset Batt Volt');
            $objPHPExcel->getActiveSheet()->setCellValue('G'.$r, 'Status');
            $objPHPExcel->getActiveSheet()->setCellValue('J'.$r, 'Run Hour');
            
            $r++;
            $objPHPExcel->getActiveSheet()->setCellValue('B'.$r, 'R');
            $objPHPExcel->getActiveSheet()->setCellValue('C'.$r, 'S');
            $objPHPExcel->getActiveSheet()->setCellValue('D'.$r, 'T');
            $objPHPExcel->getActiveSheet()->setCellValue('G'.$r, 'Genset');
            $objPHPExcel->getActiveSheet()->setCellValue('H'.$r, 'Rect');
            $objPHPExcel->getActiveSheet()->setCellValue('I'.$r, 'Maint');
            
            foreach($rows as $row)
            {
                $r++;
                #$objPHPExcel->getActiveSheet()->setCellValue('A'.$r, date('n/j/Y H:i:s', strtotime($row->dtime)));
                $dateTimeValue = PHPExcel_Shared_Date::PHPToExcel( strtotime($row->dtime) );
                $objPHPExcel->getActiveSheet()->setCellValue('A'.$r, $dateTimeValue);
                $objPHPExcel->getActiveSheet()->getStyle('A'.$r)->getNumberFormat()->setFormatCode(PHPExcel_Style_NumberFormat::FORMAT_DATE_DATETIME);
                $objPHPExcel->getActiveSheet()->setCellValue('B'.$r, $row->genset_vr);
                $objPHPExcel->getActiveSheet()->setCellValue('C'.$r, $row->genset_vs);
                $objPHPExcel->getActiveSheet()->setCellValue('D'.$r, $row->genset_vt);
                $objPHPExcel->getActiveSheet()->setCellValue('E'.$r, $row->batt_volt);
                $objPHPExcel->getActiveSheet()->setCellValue('F'.$r, $row->genset_batt_volt);
                $objPHPExcel->getActiveSheet()->setCellValue('G'.$r, $row->genset_status);
                $objPHPExcel->getActiveSheet()->setCellValue('H'.$r, $row->recti_status);
                $objPHPExcel->getActiveSheet()->setCellValue('I'.$r, $row->maintain_status);
                $objPHPExcel->getActiveSheet()->setCellValue('J'.$r, $row->run_hour);
            }
            
            foreach(range('A','J') as $columnID) { $objPHPExcel->getActiveSheet()->getColumnDimension($columnID)->setAutoSize(true); }
            
            $this->load->helper('excel');
            download_excel($objPHPExcel, 'Datalog Report_'.$from.'-'.$to);
        }
        else $this->response($rows, REST_Controller::HTTP_OK);
    }
    
}
?>