<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');
if ( ! function_exists('download_excel'))
{
    function download_excel($objPHPExcel, $filename='Report')
    {
        header('Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        header('Content-Disposition: attachment;filename="'.$filename.'.xlsx"');
        header('Cache-Control: max-age=0');
                
        $objWriter = PHPExcel_IOFactory::createWriter($objPHPExcel, 'Excel2007');
        $objWriter->save('php://output');
    }
}    
?>