<?php if (!defined('BASEPATH')) exit('No direct script access allowed');

class Home extends CI_Controller {

    public function __construct()
    {
        parent::__construct();        
        if (!$this->session->userdata('uid')) redirect('login', 'refresh');
        $this->load->model('SubnetModel','',TRUE);
        $this->load->model('NodeModel','',TRUE);
    }

    public function index()
    {
        $regions      = $this->SubnetModel->get_regions()->result();
        $i=0;
        foreach($regions as $r)
        {
            $areas  = $this->SubnetModel->get_areas($r->id)->result();
            $j=0;
            foreach($areas as $a)
            {
                $sites  = $this->NodeModel->get_by_subnet_id($a->id)->result();
                $k=0;
                foreach($sites as $s)
                {
                    $sites[$k]->alarm  = $this->NodeModel->is_has_alarm($s->id, 'node_id');
                    $k++;
                }
                $areas[$j]->children = $sites;
                $areas[$j]->alarm = $this->SubnetModel->is_has_alarm($a->id, 'subnet_id');
                $j++;
            }
            $regions[$i]->children = $areas;
            $regions[$i]->alarm = $this->SubnetModel->is_has_alarm($r->id, 'region_id');
            $i++;
        }
        $data['user'] = $this->session->userdata('name');
        $data['regions']= $regions;
        #print '<pre>';
        #print_r($data);
        #print '</pre>';
        $this->load->view('home_view', $data);
    }
}

/* End of file Home.php */
/* Location: ./application/controllers/Home.php */
?>