<?php
defined('BASEPATH') OR exit('No direct script access allowed');

// This can be removed if you use __autoload() in config.php OR use Modular Extensions
require APPPATH . '/libraries/REST_Controller.php';

if (isset($_SERVER['HTTP_ORIGIN'])) {
    header("Access-Control-Allow-Origin: {$_SERVER['HTTP_ORIGIN']}");
    header('Access-Control-Allow-Credentials: true');
    header('Access-Control-Max-Age: 86400');    // cache for 1 day
}

// Access-Control headers are received during OPTIONS requests
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {

    if (isset($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_METHOD']))
        header("Access-Control-Allow-Methods: GET, POST, OPTIONS");         

    if (isset($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']))
        header("Access-Control-Allow-Headers: {$_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']}");

    exit(0);
}
    
class Auth extends REST_Controller 
{	
	function __construct()
	{
		parent::__construct();
		$this->load->model('UserModel','',TRUE);
	}
    
    function login_post()
    {
        $username = trim($this->input->post('username'));
        $password = md5(trim($this->input->post('password')));
        
        if($username == '') {
            $postdata   = file_get_contents("php://input");
            $request    = json_decode($postdata);
            $username   = $request->username;
            $password   = md5($request->password);
        }
        
		if($this->UserModel->authenticate($username, $password)) $this->response(array('success'=>true, 'msg'=>'Login success, please wait...'), REST_Controller::HTTP_OK);
		else $this->response(array('success'=>false, 'msg'=>'Incorrect username or password !'), REST_Controller::HTTP_OK);
    }
    
    function logout_get()
    {
        $this->session->sess_destroy();
		$this->response(array('success'=>true, 'msg'=>'Logout successfully.'), REST_Controller::HTTP_OK);
    }
}
?>