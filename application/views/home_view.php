<!DOCTYPE html>
<html>
<head>
    <title>CDC Monitoring | Telkom Infra</title>
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
    <link href="<?php echo base_url(); ?>assets/stylesheets/animate.min.css" media="all" rel="stylesheet" type="text/css" />
    
    <!--[if lt IE 9]>
      <script src="<?php echo base_url(); ?>assets/javascripts/ie/html5shiv.js" type="text/javascript"></script>
      <script src="<?php echo base_url(); ?>assets/javascripts/ie/respond.min.js" type="text/javascript"></script>
    <![endif]-->
    <link rel="stylesheet" href="<?php echo base_url(); ?>assets/javascripts/angular-loading-bar/build/loading-bar.min.css"/>
    <link rel="stylesheet" href="<?php echo base_url(); ?>assets/javascripts/angular-ng-table/ng-table.min.css" />
    <link rel="stylesheet" href="<?php echo base_url(); ?>assets/stylesheets/plugins/select2/select2.css" media="all" type="text/css" />
    <link rel="stylesheet" href="<?php echo base_url(); ?>assets/stylesheets/app.map.css" media="all" type="text/css" />
    <link rel="stylesheet" href="<?php echo base_url(); ?>assets/javascripts/angular-tree/angular-tree-widget.min.css" media="all" type="text/css" />
	
    <!-- / jquery [required] -->
    <script src="<?php echo base_url(); ?>assets/javascripts/jquery/jquery.min.js" type="text/javascript"></script>
    <script src="<?php echo base_url(); ?>assets/javascripts/jquery.form.js" type="text/javascript"></script>
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
    <!-- / datepicker -->
    <script src="<?php echo base_url(); ?>assets/javascripts/plugins/bootstrap-datepicker/bootstrap-datepicker.js" type="text/javascript"></script>
    <!-- / retina -->    
    <script src="<?php echo base_url(); ?>assets/javascripts/plugins/retina/retina.js" type="text/javascript"></script>
    <!-- / theme file [required] -->
    <script src="<?php echo base_url(); ?>assets/javascripts/theme.js" type="text/javascript"></script>
    <!-- / demo file [not required!] -->
    <script src="<?php echo base_url(); ?>assets/javascripts/demo.js" type="text/javascript"></script>
    <!-- / START - page related files and scripts [optional] -->
    <script type="text/javascript">
    var BASE_URL = '<?php echo base_url(); ?>';
    var ROLE_ID  = '<?php echo $this->session->userdata('role_id'); ?>';
    var CUST_ID  = '<?php echo $this->session->userdata('customer_id'); ?>';
    var isOpened = false;
    var userInfo = {};
    </script>
    <!-- / END - page related files and scripts [optional] -->
    <script src="https://maps.googleapis.com/maps/api/js?key=AIzaSyBbl5r5Vr7-fzlvNqsIpCQiiF8Ojo738ww" type="text/javascript"></script>    
    <script src="<?php echo base_url(); ?>assets/javascripts/angular/angular.js"></script>
    <script src="<?php echo base_url(); ?>assets/javascripts/angular-ui-router/release/angular-ui-router.min.js"></script>
    <script src="<?php echo base_url(); ?>assets/javascripts/angular-ng-table/ng-table.min.js"></script>
    <script src="<?php echo base_url(); ?>assets/javascripts/angular-route/angular-route.min.js"></script>
    <script src="<?php echo base_url(); ?>assets/javascripts/angular-animate/angular-animate.js"></script>
    <script src="<?php echo base_url(); ?>assets/javascripts/angular-resource/angular-resource.js"></script>
    <script src="<?php echo base_url(); ?>assets/javascripts/json3/lib/json3.min.js"></script>
    <script src="<?php echo base_url(); ?>assets/javascripts/oclazyload/dist/ocLazyLoad.min.js"></script>
    <script src="<?php echo base_url(); ?>assets/javascripts/angular-loading-bar/build/loading-bar.min.js"></script>
    <script src="<?php echo base_url(); ?>assets/javascripts/angular-bootstrap/ui-bootstrap-tpls.min.js"></script>
    <script src="<?php echo base_url(); ?>assets/javascripts/Chart.js/Chart.min.js"></script>
    <script src="<?php echo base_url(); ?>assets/javascripts/plugins/bootbox/bootbox.min.js"></script>
    <script src="<?php echo base_url(); ?>assets/javascripts/plugins/slimscroll/jquery.slimscroll.min.js" type="text/javascript"></script>
    <script src="<?php echo base_url(); ?>assets/javascripts/plugins/typeahead/bootstrap3-typeahead.min.js"></script>
    <script src="<?php echo base_url(); ?>assets/javascripts/underscore-min.js"></script>
    <script src="<?php echo base_url(); ?>assets/javascripts/amcharts/dist/amcharts/amcharts.js"></script>
    <script src="<?php echo base_url(); ?>assets/javascripts/amcharts/dist/amcharts/serial.js" type="text/javascript"></script>
    <script src="<?php echo base_url(); ?>assets/javascripts/amcharts/dist/amcharts/themes/dark.js" type="text/javascript"></script>
    <script src="<?php echo base_url(); ?>assets/javascripts/amcharts/dist/amcharts/themes/light.js" type="text/javascript"></script>
    <script src="<?php echo base_url(); ?>assets/javascripts/amcharts/dist/amcharts/plugins/export/export.js"></script>
    <script src="<?php echo base_url(); ?>assets/javascripts/amcharts-angular/dist/amChartsDirective.js"></script>
    <script src="<?php echo base_url(); ?>assets/javascripts/plugins/select2/select2.js" type="text/javascript"></script>
	<script src="<?php echo base_url(); ?>assets/javascripts/angular-tree/angular-tree-widget.min.js" type="text/javascript"></script>
    <script src="<?php echo base_url(); ?>assets/javascripts/angular-recursion.js" type="text/javascript"></script>
    <script src="<?php echo base_url(); ?>assets/javascripts/app.context-menu.js" type="text/javascript"></script>    
    <script src="<?php echo base_url(); ?>assets/javascripts/app.js"></script>
    <script src="<?php echo base_url(); ?>assets/javascripts/app.directive.js"></script>
    <script src="<?php echo base_url(); ?>assets/javascripts/app.service.js"></script>
    <script src="<?php echo base_url(); ?>assets/javascripts/app.controller.js"></script>
  </head>
  
  <body class="contrast-red" ng-app="cdcApp">
    
    <?php $this->load->view('header_view'); ?>
    
    <div id="wrapper">
        <div id="main-nav-bg"></div>
      
        <?php $this->load->view('nav_view'); ?>
      
        <section id="content">
            <div class="container">
              
              <div class="row" id="content-wrapper">
                <div ui-view></div>
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

              <footer id="footer">
                <div class="footer-wrapper">
                  <div class="row">
                    <div class="col-sm-12 text-center">
                      Copyright &copy; 2016 PT. Sinergi Teknologi Utama
                    </div>                
                  </div>
                </div>
              </footer>
            </div>
        </section>
    </div>
    
  </body>
</html>
