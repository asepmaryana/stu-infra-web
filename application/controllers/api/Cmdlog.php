<?php
defined('BASEPATH') OR exit('No direct script access allowed');

require APPPATH . '/libraries/REST_Controller.php';

class Cmdlog extends REST_Controller 
{	
	function __construct()
	{
		parent::__construct();
		$this->load->model('OutboxModel','',TRUE);
        $this->load->model('NodeModel','',TRUE);
	}
    
    function index()
    {
        print 'cmd log ok';
    }
    
    function site_get()
    {
        $site_id    = $this->uri->segment(4);
        $doc        = $this->uri->segment(5);
        $rs         = $this->NodeModel->get_by_id($site_id);
        if($rs->num_rows() > 0)
        {
            $node       = $rs->row();
            $rows       = $this->OutboxModel->get_site_and_date_limit($node->phone, '5', '0')->result();
            if($doc == 'xls')
            {
                require_once APPPATH . 'third_party/phpexcel/PHPExcel.php';
                
                $objPHPExcel    = new PHPExcel();
                $r = 1;
                $objPHPExcel->getActiveSheet()->setCellValue('A'.$r, 'Create Date');
                $objPHPExcel->getActiveSheet()->setCellValue('B'.$r, 'Text');
                $objPHPExcel->getActiveSheet()->setCellValue('C'.$r, 'Status');
                
                foreach($rows as $row)
                {
                    $r++;
                    $objPHPExcel->getActiveSheet()->setCellValue('A'.$r, date('n/j/Y H:i:s', strtotime($row->create_date)));
                    $objPHPExcel->getActiveSheet()->setCellValue('B'.$r, $row->text);
                    $objPHPExcel->getActiveSheet()->setCellValue('C'.$r, $row->status);
                }
                
                $this->load->helper('excel');
                download_excel($objPHPExcel, 'CMD_'.$node->phone);
            }
            else $this->response($rows, REST_Controller::HTTP_OK);
        }
        else $this->response(array(), REST_Controller::HTTP_OK);
    }
    
    function save_post()
    {
        $values = json_decode(file_get_contents('php://input'), true);
        $values['text']         = $values['type'];
        #unset($values['type']);
        $values['create_date']  = date('Y-m-d H:i:s');
        
        $rs = $this->OutboxModel->get_last($values['recipient'], 'U');
        if($rs->num_rows() > 0) $this->response(array('success'=>false, 'msg'=>'Command failed.'), REST_Controller::HTTP_OK);
        else {
            $this->OutboxModel->save($values);
            $this->response(array('success'=>true, 'msg'=>'Command will be processed.'), REST_Controller::HTTP_OK);
        }
        $rs->free_result();
    }
}
?>