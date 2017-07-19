<?php $this->load->view('template/v_Head'); ?>

<?php $this->load->view('template/_HeaderInfo'); ?>

<?php $this->load->view('template/_TopNavBar'); ?>

<div id="wrapper">
    <div id="layout-static">

        <!--LeftSideBar-->
        <?php $this->load->view('template/_LeftBarMenu'); ?>
        <!--LeftSideBar-->

        <!--Content Page-->
        <div class="static-content-wrapper">
            <div class="static-content">
                <div class="page-content">
                    <div class="page-heading">
                        <h1 id="node_title">Monitoring</h1>
                        <div class="options hide">
                            <div class="btn-toolbar">
                                <a href="#" class="btn btn-default"><i class="fa fa-fw fa-wrench"></i></a>
                            </div>
                        </div>
                    </div>
                    <ol class="breadcrumb">
                        <li><a href="<?php echo base_url(); ?>dashboard">Home</a></li>
                        <li><a href="#">Site</a></li>
                        <li class="active hide"><a href="#">Scroll Sidebar</a></li>
                    </ol>
                    <div class="container-fluid">

                        <div class="row">
                            <div class="col-md-12">
                                <div class="panel panel-default">
                                    <div class="panel-heading">
                        				<h2 id="last_updated"></h2>
                        				<div class="options">
                        					<ul class="nav nav-tabs">
                        		              <li class="active"><a href="#montabs" data-toggle="tab"><i class="fa fa-dashboard"></i> Monitoring</a></li>
                        		              <li><a href="#datatabs" data-toggle="tab"><i class="fa fa-database"></i> Data log</a></li>
                                              <li><a href="#alarmtabs" data-toggle="tab"><i class="fa fa-bell"></i> Alarm log</a></li>
                        		            </ul>
                        				</div>
                        			</div>
                                    <div class="panel-body">
                                        <div class="tab-content">
                                            <div class="tab-pane active" id="montabs">
                                                <div class="row">
                                                    <div class="col-md-6">
                                                        <table>
                                                            <tbody>
                                                                <tr>
                                                                    <td><img src="<?php echo base_url(); ?>assets/images/low_fuel_off.png" border="0" id="lf" /></td>
                                                                    <td><img src="<?php echo base_url(); ?>assets/images/genset_on.png" border="0" id="gs" /></td>
                                                                    <td><img src="<?php echo base_url(); ?>assets/images/breaker_on.png" border="0" id="bs" /></td>
                                                                    <td><img src="<?php echo base_url(); ?>assets/images/recti_on.png" border="0" id="rs" /></td>
                                                                    <td><img src="<?php echo base_url(); ?>assets/images/bts_load.png" border="0" /></td>
                                                                </tr>
                                                                <tr>
                                                                    <td>&nbsp;</td>
                                                                    <td><img src="<?php echo base_url(); ?>assets/images/batt_genset.png" border="0" id="bg" /></td>
                                                                    <td>&nbsp;</td>
                                                                    <td><img src="<?php echo base_url(); ?>assets/images/low_batt_off.png" border="0" id="lb" /></td>
                                                                    <td>&nbsp;</td>
                                                                </tr>
                                                            </tbody>
                                                        </table>
                                                    </div>
                                                    <div class="col-md-6">
                                                        <table cellpadding="0" cellspacing="0" border="0" class="table table-striped table-bordered" id="tablearea">
                                                            <thead>
                                                                <tr>
                                                                    <th>Parameter</th>
                                                                    <th>Value</th>
                                                                    <th>Unit</th>
                                                                </tr>
                                                            </thead>
                                                            <tbody>
                                                                <tr>
                                                                    <td>Genset Voltage</td>
                                                                    <td id="gv_val"></td>
                                                                    <td>V</td>
                                                                </tr>
                                                                <!--
                                                                <tr>
                                                                    <td>Genset Current</td>
                                                                    <td id="gc_val"></td>
                                                                    <td>A</td>
                                                                </tr>
                                                                -->
                                                                <tr>
                                                                    <td>Genset Batt Voltage</td>
                                                                    <td id="gbv_val"></td>
                                                                    <td>V</td>
                                                                </tr>
                                                                <tr>
                                                                    <td>Batt Voltage</td>
                                                                    <td id="bv_val"></td>
                                                                    <td>V</td>
                                                                </tr>
                                                                <tr>
                                                                    <td>Batt Current</td>
                                                                    <td id="bc_val"></td>
                                                                    <td>A</td>
                                                                </tr>
                                                            </tbody>
                                                        </table>
                                                    </div>
                                                </div>
                                                
                                                <div class="row">
                                                    <div class="col-md-12">
                                                        <div class="panel panel-default">
                                                            <div class="panel-heading">
                                                				<h2>Active Alarm</h2>
                                                            </div>
                                                            <div class="panel-body">
                                                                <table cellpadding="0" cellspacing="0" border="0" class="table table-striped table-bordered" id="tablealarm">
                                                                    <thead>
                                                                        <tr>
                                                                            <th>Region</th>
                                                                            <th>Site</th>
                                                                            <th>Date Time</th>
                                                                            <th>Severity</th>
                                                                            <th>Alarm Name</th>
                                                                        </tr>
                                                                    </thead>
                                                                    <tbody>
                                                                    </tbody>
                                                                </table>
                                                            </div>
                                                        </div>
                                                    </div>
                                                                
                                                </div>
                        
                                            </div>
                                            <div class="tab-pane" id="datatabs">
                                                <div class="row">
                                                    <div class="col-md-12">
                                                        <form class="form-inline" role="form">
                                                            <div class="row">
                                                                <div class="col-md-12">
                                                                    <div class="form-group">
                                        								<label class="sr-only" for="exampleInputEmail2">Start Date</label>
                                        								<input type="email" class="form-control" id="startDate" placeholder="Start Date"/>
                                        							</div>
                                                                    <div class="form-group">
                                        								<label class="sr-only" for="exampleInputEmail2">Stop Date</label>
                                        								<input type="email" class="form-control" id="stopDate" placeholder="Stop Date"/>
                                        							</div>
                                                                    <div class="form-group">
                                                                        <div class="btn-group">
                                                                            <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown">
                                                                                View <span class="caret"></span>
                                                                            </button>
                                                                            <ul class="dropdown-menu" role="menu">
                                                                                <li><a href="#" onclick="node_data_log('json')">As Table</a></li>
                                                                                <li><a href="#" onclick="node_data_log('chart')">As Chart</a></li>
                                                                                <li class="divider"></li>
                                                                                <li><a href="#" onclick="node_data_log('xls')">As Excel</a></li>
                                                                            </ul>
                                                                        </div>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                        </form>
                                                    </div>
                                                </div>
                                                <br />
                                                <div class="row">
                                                    <div class="col-md-12">
                                                        <table cellpadding="0" cellspacing="0" border="0" class="table table-striped table-bordered" id="tabledatalog">
                                                            <thead>
                                                                <tr>
                                                                    <th rowspan="2" class="text-center">Date Time</th>
                                                                    <th colspan="3" class="text-center">Genset Voltage</th>
                                                                    <th colspan="3" class="text-center">Genset Current</th>
                                                                    <th colspan="2" class="text-center">Battery</th>
                                                                    <th rowspan="2" class="text-center">Genset Batt Volt</th>
                                                                    <th colspan="3" class="text-center">Status</th>
                                                                    <th colspan="4" class="text-center">Alarm</th>
                                                                </tr>
                                                                <tr>
                                                                    <th class="text-center">R</th>
                                                                    <th class="text-center">S</th>
                                                                    <th class="text-center">T</th>
                                                                    <th class="text-center">R</th>
                                                                    <th class="text-center">S</th>
                                                                    <th class="text-center">T</th>
                                                                    <th class="text-center">Volt</th>
                                                                    <th class="text-center">Curr</th>
                                                                    <th class="text-center">Genset</th>
                                                                    <th class="text-center">Rect</th>
                                                                    <th class="text-center">Breaker</th>
                                                                    <th class="text-center">GF</th>
                                                                    <th class="text-center">LF</th>
                                                                    <th class="text-center">RF</th>
                                                                    <th class="text-center">BL</th>
                                                                </tr>
                                                            </thead>
                                                            <tbody>
                                                            </tbody>
                                                        </table>
                                                    </div>
                                                </div>      
                                            </div>
                                            <div class="tab-pane" id="alarmtabs">
                                                <div class="row">
                                                    <div class="col-md-12">
                                                        <form class="form-inline" role="form">
                                                            <div class="row">
                                                                <div class="col-md-12">
                                                                    <div class="form-group">
                                        								<label class="sr-only" for="exampleInputEmail2">Start Date</label>
                                        								<input type="email" class="form-control" id="startDateAlarm" placeholder="Start Date"/>
                                        							</div>
                                                                    <div class="form-group">
                                        								<label class="sr-only" for="exampleInputEmail2">Stop Date</label>
                                        								<input type="email" class="form-control" id="stopDateAlarm" placeholder="Stop Date"/>
                                        							</div>
                                                                    <div class="form-group">
                                                                        <div class="btn-group">
                                                                            <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown">
                                                                                View <span class="caret"></span>
                                                                            </button>
                                                                            <ul class="dropdown-menu" role="menu">
                                                                                <li><a href="#" onclick="node_alarm_log('json')">As Table</a></li>
                                                                                <li class="divider"></li>
                                                                                <li><a href="#" onclick="node_alarm_log('xls')">As Excel</a></li>
                                                                            </ul>
                                                                        </div>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                        </form>
                                                    </div>
                                                </div>
                                                
                                                <br />
                                                <div class="row">
                                                    <div class="col-md-12">
                                                        <table cellpadding="0" cellspacing="0" border="0" class="table table-striped table-bordered" id="tablealarmlog">
                                                            <thead>
                                                                <tr>
                                                                    <th class="text-center">Region</th>
                                                                    <th class="text-center">Site</th>
                                                                    <th class="text-center">Start</th>
                                                                    <th class="text-center">Stop</th>
                                                                    <th class="text-center">Severity</th>
                                                                    <th class="text-center">Alarm Name</th>
                                                                </tr>
                                                            </thead>
                                                            <tbody>
                                                            </tbody>
                                                        </table>
                                                    </div>
                                                </div>
                                                
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        
                        
                    </div> <!-- .container-fluid -->
                </div> <!-- #page-content -->
            </div>

            <?php $this->load->view('template/_Footer');?>

        </div>
        <!--Content Page-->


    </div>
</div>

<?php $this->load->view('template/_RightBarMenu');?>

<?php $this->load->view('template/v_Foot'); ?>

<script src="<?php echo base_url();?>assets/plugins/bootstrap-datepicker/bootstrap-datepicker.js"></script>
<script src="<?php echo base_url();?>assets/plugins/amcharts/amcharts/amcharts.js" type="text/javascript"></script>
<script src="<?php echo base_url();?>assets/plugins/amcharts/amcharts/serial.js" type="text/javascript"></script>
<script src="<?php echo base_url();?>assets/plugins/amcharts/amcharts/plugins/export/export.min.js"></script>
<script src="https://maps.googleapis.com/maps/api/js?key=AIzaSyBbl5r5Vr7-fzlvNqsIpCQiiF8Ojo738ww"></script>
<script src="<?php echo base_url() ?>assets/js/app/app.context-menu.js"></script>
<script src="<?php echo base_url() ?>assets/js/app/app.core.js"></script>

<script type="text/javascript">
    var role_id = '<?php echo $this->session->userdata('role_id'); ?>';
    var cust_id  = '<?php echo $this->session->userdata('customer_id'); ?>';
    
    function node_data_log(doc)
    {
        var url_to_get = base_url+'api/datalog/site/<?php echo $node_id; ?>/'+$('#startDate').val()+'/'+$('#stopDate').val();
        if(doc == 'json') {
            $.get(url_to_get+'/'+doc, {}, function(msg){
                var table = $('#tabledatalog').DataTable();
                table.clear().draw();                            
                for(var i=0; i<msg.data.length; i++)
                {
                    table.row.add([
                        msg.data[i].ddtime,
                        msg.data[i].genset_vr,
                        msg.data[i].genset_vs,
                        msg.data[i].genset_vt,
                        msg.data[i].genset_cr,
                        msg.data[i].genset_cs,
                        msg.data[i].genset_ct,
                        msg.data[i].batt_volt,
                        msg.data[i].batt_curr,
                        msg.data[i].genset_batt_volt,
                        msg.data[i].genset_status,
                        msg.data[i].recti_status,
                        msg.data[i].breaker_status,
                        msg.data[i].genset_fail,
                        msg.data[i].low_fuel,
                        msg.data[i].recti_fail,
                        msg.data[i].batt_low
                    ]).draw();
                }
            },'json');
        }
        else if(doc == 'xls') window.open(url_to_get+'/'+doc);
    }
    
    function node_alarm_log(doc)
    {
        var url_to_get = base_url+'api/alarmlog/site/<?php echo $node_id; ?>/'+$('#startDateAlarm').val()+'/'+$('#stopDateAlarm').val();
        if(doc == 'json') {
            $.get(url_to_get+'/'+doc, {}, function(msg){
                var table = $('#tablealarmlog').DataTable();
                table.clear().draw();                            
                for(var i=0; i<msg.data.length; i++)
                {
                    table.row.add([
                        msg.data[i].regional,
                        msg.data[i].site,
                        msg.data[i].ddtime,
                        msg.data[i].ddtime_end,
                        msg.data[i].severity,
                        msg.data[i].alarm_label
                    ]).draw();
                }
            },'json');
        }
        else if(doc == 'xls') window.open(url_to_get+'/'+doc);
    }
    
    function node_monitoring()
    {
        $.get(base_url+'api/node/info/<?php echo $node_id; ?>', {}, function(res){ 
             var node = res.data;
             var mode = '';
             if(node.cdc_mode == '1') mode = 'Manual';
             else if(node.cdc_mode == '2') mode = 'Timer';
             else if(node.cdc_mode == '3') mode = 'Rect Command';
             else mode = 'Treshold Batt Voltage';
             $('#node_title').html(node.name+' - '+node.phone+' [CDC Mode: '+mode+']');
             $('#last_updated').html('Last Updated: '+node.updated_at+' WIB');
             $('#gv_val').html(node.genset_vr+' | '+node.genset_vs+' | '+node.genset_vt);
             $('#gc_val').html(node.genset_cr+' | '+node.genset_cs+' | '+node.genset_ct);
             $('#gbv_val').html(node.genset_batt_volt);
             $('#bv_val').html(node.batt_volt);
             $('#bc_val').html(node.batt_curr);
             
             if(node.low_fuel == '1') $('#lf').attr('src', base_url+'assets/images/low_fuel_on.png');
             else $('#lf').attr('src', base_url+'assets/images/low_fuel_off.png');
             
             if(node.genset_fail == '1') $('#gs').attr('src', base_url+'assets/images/genset_fail.png');
             else if(node.genset_status == '1') $('#gs').attr('src', base_url+'assets/images/genset_on.png');
             else $('#gs').attr('src', base_url+'assets/images/genset_off.png');
             
             if(node.breaker_status == '1') $('#bs').attr('src', base_url+'assets/images/breaker_on.png');
             else $('#bs').attr('src', base_url+'assets/images/breaker_off.png');
             
             if(node.recti_fail == '1') $('#rs').attr('src', base_url+'assets/images/recti_fail.png');
             else if(node.recti_status == '1') $('#rs').attr('src', base_url+'assets/images/recti_on.png');
             else $('#rs').attr('src', base_url+'assets/images/recti_off.png');
             
             if(node.batt_low == '1') $('#lb').attr('src', base_url+'assets/images/low_batt_on.png');
             else $('#lb').attr('src', base_url+'assets/images/low_batt_off.png');
             
        },'json');
        
        $.get(base_url+'api/alarm/node/<?php echo $node_id; ?>', {}, function(msg){
            var table = $('#tablealarm').DataTable();
            table.clear().draw();                            
            for(var i=0; i<msg.data.length; i++)
            {
                table.row.add([
                    msg.data[i].regional,
                    msg.data[i].site,
                    msg.data[i].ddtime,
                    msg.data[i].severity,
                    msg.data[i].alarm_label
                ]).draw();
            }
        },'json');
    
    }
    
    setInterval(function(){ node_monitoring(); }, 15 * 1000);
    
    $(document).ready(function(){
        node_monitoring();
        $('#tablealarm').dataTable();
        $('#tabledatalog').dataTable();
        $('#tablealarmlog').dataTable();
        $("#startDate").datepicker({todayHighlight: true, format:'yyyy-mm-dd'});
        $("#stopDate").datepicker({todayHighlight: true, format:'yyyy-mm-dd'});
        $("#startDateAlarm").datepicker({todayHighlight: true, format:'yyyy-mm-dd'});
        $("#stopDateAlarm").datepicker({todayHighlight: true, format:'yyyy-mm-dd'});
        //$('#tabledatalog').dataTable({"paging": false, "info": false});
    });
</script>