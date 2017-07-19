<!DOCTYPE html>
<html>
<head>
    <title>Sign in | CDC Telkom Infra</title>
    <meta content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" name="viewport"/>
    <meta content="text/html;charset=utf-8" http-equiv="content-type"/>
    <meta content="" name="description"/>
    <!-- <link href="<?php echo base_url(); ?>assets/images/meta_icons/favicon.ico" rel="shortcut icon" type="image/x-icon"/> -->
    <link href="<?php echo base_url(); ?>assets/images/meta_icons/apple-touch-icon.png" rel="apple-touch-icon-precomposed"/>
    <link href="<?php echo base_url(); ?>assets/images/meta_icons/apple-touch-icon-57x57.png" rel="apple-touch-icon-precomposed" sizes="57x57"/>
    <link href="<?php echo base_url(); ?>assets/images/meta_icons/apple-touch-icon-72x72.png" rel="apple-touch-icon-precomposed" sizes="72x72"/>
    <link href="<?php echo base_url(); ?>assets/images/meta_icons/apple-touch-icon-114x114.png" rel="apple-touch-icon-precomposed" sizes="114x114"/>
    <link href="<?php echo base_url(); ?>assets/images/meta_icons/apple-touch-icon-144x144.png" rel="apple-touch-icon-precomposed" sizes="144x144"/>
    <!-- / START - page related stylesheets [optional] -->
    
    <!-- / END - page related stylesheets [optional] -->
    <!-- / bootstrap [required] -->
    <link href="<?php echo base_url(); ?>assets/stylesheets/bootstrap/bootstrap.css" media="all" rel="stylesheet" type="text/css" />
    <!-- / theme file [required] -->
    <link href="<?php echo base_url(); ?>assets/stylesheets/light-theme.css" media="all" id="color-settings-body-color" rel="stylesheet" type="text/css" />
    <!-- / coloring file [optional] (if you are going to use custom contrast color) -->
    <link href="<?php echo base_url(); ?>assets/stylesheets/theme-colors.css" media="all" rel="stylesheet" type="text/css" />
    <!-- / demo file [not required!] -->
    <link href="<?php echo base_url(); ?>assets/stylesheets/demo.css" media="all" rel="stylesheet" type="text/css" />
    <!--[if lt IE 9]>
      <script src="<?php echo base_url(); ?>assets/javascripts/ie/html5shiv.js" type="text/javascript"></script>
      <script src="<?php echo base_url(); ?>assets/javascripts/ie/respond.min.js" type="text/javascript"></script>
    <![endif]-->
  </head>
  <body class="contrast-red login contrast-background">
    <div class="middle-container">
      <div class="middle-row">
        <div class="middle-wrapper">
          <div class="login-container-header">
            <div class="container">
              <div class="row">
                <div class="col-sm-12">
					<h1 class="text-center title">CDC Monitoring System</h1>
                </div>
              </div>
            </div>
          </div>
          <div class="login-container">
            <div class="container">
              <div class="row">
                <div class="col-sm-4 col-sm-offset-4">
				  <div class="text-center">
                    <img src="<?php echo base_url(); ?>assets/images/infra.png" border="0"/>
                  </div>
				  <br/>
                  <form action="#" class="validate-form" method="post" id="form_login">
                    <div class="form-group">
                      <div class="controls with-icon-over-input">
                        <input placeholder="Username" class="form-control" data-rule-required="true" name="username" id="username" type="text" />
                        <i class="icon-user text-muted"></i>
                      </div>
                    </div>
                    <div class="form-group">
                      <div class="controls with-icon-over-input">
                        <input placeholder="Password" class="form-control" data-rule-required="true" name="password" id="password" type="password" />
                        <i class="icon-lock text-muted"></i>
                      </div>
                    </div>
                    <div class="checkbox">
                      <label for="remember_me">
                        <input id="remember_me" name="remember_me" type="checkbox" value="1"/>
                        Remember me
                      </label>
                    </div>
                    <button class="btn btn-block" type="button" onclick="login()">Sign in</button>
                  </form>
				  <!--
                  <div class="text-center">
                    <hr class="hr-normal">
                    <a href="forgot_password.html">Forgot your password?</a>
                  </div>
				  -->
                </div>
              </div>
            </div>
          </div>
          <div class="login-container-footer">
            <div class="container">
              <div class="row">
                <div class="col-sm-12">
                  <div class="text-center">
                    <a href="http://www.sinergiteknologi.com" target="_blank">Copyright &copy;  PT. Sinergi Teknologi Utama - 2016</a>
                  </div>
                </div>
              </div>
            </div>
          </div>
		  
		  <div class="modal fade" id="frmDlg" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">                    
			<div class="modal-dialog">
				<div class="modal-content">
					<div class="modal-header">                        
						<h4 class="modal-title" id="dlg_title"></h4>
					</div>
					<div class="modal-body" id="dlg_body"></div>
					<div class="modal-footer">
						<button type="button" class="btn btn-default" data-dismiss="modal">Close</button>                                        
					</div>
				</div>
			</div>
		</div>

        </div>
      </div>
    </div>
    <!-- / jquery [required] -->
    <script src="<?php echo base_url(); ?>assets/javascripts/jquery/jquery.min.js" type="text/javascript"></script>
	<script src="<?php echo base_url(); ?>assets/javascripts/jquery/jquery.form.js" type="text/javascript"></script>
    <!-- / jquery mobile (for touch events) -->
    <script src="<?php echo base_url(); ?>assets/javascripts/jquery/jquery.mobile.custom.min.js" type="text/javascript"></script>
    <!-- / jquery migrate (for compatibility with new jquery) [required] -->
    <script src="<?php echo base_url(); ?>assets/javascripts/jquery/jquery-migrate.min.js" type="text/javascript"></script>
    <!-- / jquery ui -->
    <script src="<?php echo base_url(); ?>assets/javascripts/jquery/jquery-ui.min.js" type="text/javascript"></script>
    <!-- / jQuery UI Touch Punch -->
    <script src="<?php echo base_url(); ?>assets/javascripts/plugins/jquery_ui_touch_punch/jquery.ui.touch-punch.min.js" type="text/javascript"></script>
    <!-- / bootstrap [required] -->
    <script src="<?php echo base_url(); ?>assets/javascripts/bootstrap/bootstrap.js" type="text/javascript"></script>
    <!-- / modernizr -->
    <script src="<?php echo base_url(); ?>assets/javascripts/plugins/modernizr/modernizr.min.js" type="text/javascript"></script>
    <!-- / retina -->
    <script src="<?php echo base_url(); ?>assets/javascripts/plugins/retina/retina.js" type="text/javascript"></script>
    <!-- / theme file [required] -->
    <script src="<?php echo base_url(); ?>assets/javascripts/theme.js" type="text/javascript"></script>
    <!-- / demo file [not required!] -->
    <script src="<?php echo base_url(); ?>assets/javascripts/demo.js" type="text/javascript"></script>
    <!-- / START - page related files and scripts [optional] -->
    <script src="<?php echo base_url(); ?>assets/javascripts/plugins/validate/jquery.validate.min.js" type="text/javascript"></script>
    <script src="<?php echo base_url(); ?>assets/javascripts/plugins/validate/additional-methods.js" type="text/javascript"></script>
    <!-- / END - page related files and scripts [optional] -->
	<script type="text/javascript">var base_url = "<?php echo base_url(); ?>";</script>
	<script src="<?php echo base_url();?>assets/javascripts/login.js" type="text/javascript"></script>
  </body>
</html>
