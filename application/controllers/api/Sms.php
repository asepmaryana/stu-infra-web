<?php
defined('BASEPATH') OR exit('No direct script access allowed');

require APPPATH . '/libraries/REST_Controller.php';

class Sms extends REST_Controller 
{	
	function __construct()
	{
		parent::__construct();
		
		$this->load->model('SubnetModel','',TRUE);
        $this->load->model('NodeModel','',TRUE);
        $this->load->model('InboxModel','',TRUE);
        $this->load->model('DatalogModel','',TRUE);
        
	}
    
    function index()
    {
        print 'SMS API';
    }
    
    function trap()
    {
        $sender         = (trim($this->input->post('sender')) == '') ? '' : trim($this->input->post('sender'));
        $message_date   = (trim($this->input->post('message_date')) == '') ? '' : trim($this->input->post('message_date'));
        $receive_date   = (trim($this->input->post('receive_date')) == '') ? '' : trim($this->input->post('receive_date'));
        $text           = (trim($this->input->post('text')) == '') ? '' : trim($this->input->post('text'));
        $gateway_id     = (trim($this->input->post('gateway_id')) == '') ? '' : trim($this->input->post('gateway_id'));
        
        /*
        $sender = '6285210588635';
        $text = 'Time=29- 9-2016  8:35:40
        GV=207.7,207.8,207.9
        GI=1.0,1.2,1.4
        BV=48.7
        BI=0.0
        GBV=12.0
        GO=1
        RS=1
        BS=0
        GF=0
        LF=1
        RF=0
        BLV=0
        CDC=1';
        */
        #print $sender.'<br/>'.$text.'<br/>';

        if(!empty($sender) && !empty($text))
        {
            if(substr($sender, 0, 2) == '62') $sender = '0'.substr($sender, 2, strlen($sender));
            ##print $sender.'<br/>';
            $rs = $this->NodeModel->get_by_phone($sender);
            if($rs->num_rows() > 0) {
                #print 'exists<br/>';
                $node = $rs->row();
                
                #parse text/content
                $content    = array();
                if(preg_match("/\r/", $text)) $content = explode("\r", $text);
                else $content = explode("\n", $text);
                
                $values = array();
                foreach($content as $msg)
                {
                    #print $msg.'<br/>';
                    if(trim($msg) == '') continue;
                    else
                    {
                        list($key, $val) = explode('=', trim($msg));
                        if(strtoupper($key) == 'TIME') {
                            list($date, $hour)      = explode(' ', $val);
                            list($dd, $mm, $yy)     = explode('-', $date);
                            list($jm, $men, $det)   = explode(':', $hour);
                            
                            $dd = trim($dd);
                            $mm = trim($mm);
                            $yy = trim($yy);
                            $jm = trim($jm);
                            $men = trim($men);
                            $det = trim($det);
                            
                            if(strlen($dd) == 1) $dd = '0'.$dd;
                            if(strlen($mm) == 1) $mm = '0'.$mm;                            
                            if(strlen($jm)  == 1) $jm = '0'.$jm;
                            if(strlen($men) == 1) $men = '0'.$men;
                            if(strlen($det) == 1) $det = '0'.$det;
                            
                            $val    = $yy.'-'.$mm.'-'.$dd.' '.$jm.':'.$men.':'.$det;
                            $values['updated_at']    = trim($val);
                        }
                        elseif(strtoupper($key) == 'GV') {
                            if(count(explode(',', trim($val))) == 3) {
                                list($gvr, $gvs, $gvt) = explode(',', trim($val));
                                $values['genset_vr'] = $gvr;
                                $values['genset_vs'] = $gvs;
                                $values['genset_vt'] = $gvt;
                            }
                        }
                        elseif(strtoupper($key) == 'GI') {
                            if(count(explode(',', trim($val))) == 3) {
                                list($gcr, $gcs, $gct) = explode(',', trim($val));
                                $values['genset_cr'] = $gcr;
                                $values['genset_cs'] = $gcs;
                                $values['genset_ct'] = $gct;
                            }
                        }
                        elseif(strtoupper($key) == 'BV') $values['batt_volt']           = trim($val);
                        elseif(strtoupper($key) == 'BI') $values['batt_curr']           = trim($val);
                        elseif(strtoupper($key) == 'GBV')$values['genset_batt_volt']    = trim($val);
                        elseif(strtoupper($key) == 'GO') $values['genset_status']       = trim($val);
                        elseif(strtoupper($key) == 'RS') $values['recti_status']        = trim($val);
                        elseif(strtoupper($key) == 'BS') $values['breaker_status']      = trim($val);
                        elseif(strtoupper($key) == 'GF') $values['genset_fail']         = trim($val);
                        elseif(strtoupper($key) == 'LF') $values['low_fuel']            = trim($val);
                        elseif(strtoupper($key) == 'RF') $values['recti_fail']          = trim($val);
                        elseif(strtoupper($key) == 'BLV')$values['batt_low']            = trim($val);
                        elseif(strtoupper($key) == 'CDC')$values['cdc_mode']            = trim($val);
                    }
                }
                
                #print '<pre>';
                #print_r($values);
                #print '</pre>';
                if(strtotime($values['updated_at']) > strtotime($node->updated_at)) {
                    $this->NodeModel->update($node->id, $values);
                    print 'OK';
                }
                else {
                    $values['node_id']  = $node->id;
                    $values['dtime']    = $values['updated_at'];
                    unset($values['updated_at']);
                    $this->DatalogModel->save($values);
                    print 'OLD TIME';
                }
            }
            else 'NOT FOUND';
            $rs->free_result();
        }
        else print 'NOK';
    }
}
?>