<?php
defined('BASEPATH') OR exit('No direct script access allowed');

require APPPATH . '/libraries/REST_Controller.php';

class Smslog extends REST_Controller 
{	
	function __construct()
	{
		parent::__construct();
		$this->load->model('InboxModel','',TRUE);
        $this->load->model('NodeModel','',TRUE);
	}
    
    function index()
    {
        print 'smslog ok';
    }
    
    function site_get()
    {
        $site_id    = $this->uri->segment(4);
        $from       = $this->uri->segment(5);
        $to         = $this->uri->segment(6);
        $doc        = $this->uri->segment(7);
        
        $rs         = $this->NodeModel->get_by_id($site_id);
        if($rs->num_rows() > 0)
        {
            $node       = $rs->row();
            $rows       = $this->InboxModel->get_site_and_date($node->phone, $from, $to)->result();
            if($doc == 'xls')
            {
                require_once APPPATH . 'third_party/phpexcel/PHPExcel.php';
                
                $objPHPExcel    = new PHPExcel();
                $r = 1;
                $objPHPExcel->getActiveSheet()->setCellValue('A'.$r, 'Message Date');
                $objPHPExcel->getActiveSheet()->setCellValue('B'.$r, 'Receive Date');
                $objPHPExcel->getActiveSheet()->setCellValue('C'.$r, 'Text');
                
                foreach($rows as $row)
                {
                    $r++;
                    $objPHPExcel->getActiveSheet()->setCellValue('A'.$r, date('n/j/Y H:i:s', strtotime($row->message_date)));
                    $objPHPExcel->getActiveSheet()->setCellValue('B'.$r, date('n/j/Y H:i:s', strtotime($row->receive_date)));
                    $objPHPExcel->getActiveSheet()->setCellValue('C'.$r, $row->text);
                }
                
                $this->load->helper('excel');
                download_excel($objPHPExcel, 'SMS_'.$node->phone.'_'.$from.'-'.$to);
            }
            else $this->response($rows, REST_Controller::HTTP_OK);
        }
        else $this->response(array(), REST_Controller::HTTP_OK);
    }
}
?>