var markers = {};
var contextmenuDir;
var contextmenuDir;
var cevent;
var map;
var infoWindow = new google.maps.InfoWindow();
var lat;
var lng;
var currSite;
var currEvent;

function node_turn(cmd)
{
    $('.contextmenu').remove();
    bootbox.confirm("Do you want to turn "+cmd+" "+currSite.name+" ?", function(res) {
        if(res) {
            $.post(BASE_URL+'api/node/cmd', {site_id:currSite.id, command:cmd},function(result){
                if (result.success) show_dlg_msg('Success', result.msg);
                else show_dlg_msg('Exception', result.msg);
                setTimeout(function(){ $('#frmDlg').modal('toggle'); }, 3000);
            },'json');
        }
    });
}

function node_add()
{
    currSite = null;
    $('#form_site').resetForm();
    $('#dlg_title_site').html('Add New Site');
    $('.contextmenu').remove();        
    
    $.get(BASE_URL+'api/subnet/all', {},function(result){
        $('#subnet_id').find('option').remove().end().append('<option value="">- Select -</option>');
        var rows = result.data;
        for(var i=0; i<rows.length; i++) $('#subnet_id').append($("<option></option>").attr("value",rows[i].id).text(rows[i].name));
    },'json');
    
    $.get(BASE_URL+'api/customer/all', {},function(result){
        $('#customer_id').find('option').remove().end().append('<option value="">- Select -</option>');
        var rows = result.data;
        for(var i=0; i<rows.length; i++) $('#customer_id').append($("<option></option>").attr("value",rows[i].id).text(rows[i].name));        
    },'json');
    
    $('#latitude').val(lat);
    $('#longitude').val(lng);
    $('#frmSiteDlg').modal('show');
}

function node_edit()
{
    //alert(window.location);    
    $('#form_site').resetForm();
    $('#dlg_title_site').html('Edit Site '+currSite.name);
    $('.contextmenu').remove();
    
    $('#id').val(currSite.id);
    $('#name').val(currSite.name);
    $('#phone').val(currSite.phone);
    $('#latitude').val(currSite.latitude);
    $('#longitude').val(currSite.longitude);
    
    $.get(BASE_URL+'api/subnet/all', {},function(result){
        $('#subnet_id').find('option').remove().end().append('<option value="">- Select -</option>');
        var rows = result.data;
        for(var i=0; i<rows.length; i++) $('#subnet_id').append($("<option></option>").attr("value",rows[i].id).text(rows[i].name));
        $('#subnet_id').val(currSite.subnet_id);
    },'json');
    
    $.get(BASE_URL+'api/customer/all', {},function(result){
        $('#customer_id').find('option').remove().end().append('<option value="">- Select -</option>');
        var rows = result.data;
        for(var i=0; i<rows.length; i++) $('#customer_id').append($("<option></option>").attr("value",rows[i].id).text(rows[i].name));
        $('#customer_id').val(currSite.customer_id);
    },'json');
    
    $('#frmSiteDlg').modal('show');
}

function node_delete()
{
    $('.contextmenu').remove();
    bootbox.confirm("Do you want to delete "+currSite.name+" ?", function(res) {
        if(res) {
            $.post(BASE_URL+'api/node/delete/'+currSite.id, {}, function(result){
                if(result.success) {
                    node = markers[currSite.id];
                    node.setMap(null);
                }
                else {
                    show_dlg_msg('Exception', result.msg);
                    setTimeout(function(){ $('#frmDlg').modal('toggle'); }, 3000);
                }
            },'json');
        }
    });
}

function node_datalog()
{
    $('.contextmenu').remove();
    $('#table_out').hide();
    $('#chart_out').hide();
    $('#dlg_title_site_data').html(currSite.name + ' - ' +currSite.subnet+ ' - Data History');
    $("#from").datepicker({todayHighlight: true, format:'yyyy-mm-dd'});
    $("#to").datepicker({todayHighlight: true, format:'yyyy-mm-dd'});
    $('#frmDataDlg').modal('show');
}

function node_datalog_show(doc)
{
    if($("#from").val().trim() == '') bootbox.alert('Please define start date');
    else if($("#to").val().trim() == '') bootbox.alert('Please define stop date');
    else {
        var url_to_get = BASE_URL+'api/datalog/site/'+currSite.id+'/'+$("#from").val().trim()+'/'+$("#to").val().trim();
        if(doc == 'xls') window.open(url_to_get+'/xls');
        else if(doc == 'tbl') {
            $.get(url_to_get+'/json', {}, function(msg){
                var table = $('#tabledatalog').DataTable();
                table.clear().draw();                            
                for(var i=0; i<msg.data.length; i++)
                {
                    status = 'OFF';
                    if(msg.data[i].status == '1' && parseFloat(msg.data[i].iload) > 1) status = 'ON';
                    else if(msg.data[i].status == '1' && parseFloat(msg.data[i].iload) < 1) status = 'STANDBY';
                    
                    table.row.add([
                        msg.data[i].ddtime,
                        status,
                        msg.data[i].vbatt,
                        msg.data[i].ibatt,
                        msg.data[i].iload,
                        msg.data[i].temperature_ctrl,
                        msg.data[i].temperature_batt
                    ]).draw();
                }
            },'json');
            
            $('#table_out').show();
            $('#chart_out').hide();
        }
        else {
            $.get(url_to_get+'/json', {}, function(msg){
                for(var j=0; j<msg.data.length; j++) msg.data[j].jsdate = new Date(msg.data[j].jsdate);
                AmCharts.makeChart("chart_out", {
                    "type": "serial",
                    "theme": "light",
                    "marginTop":0,
                    "marginRight": 80,
                    "dataProvider": msg.data,
                    "valueAxes": [{
                        "axisAlpha": 0,
                        "position": "left"
                    }],
                    "graphs": [
                        {
                            "id":"vbatt",
                            "balloonText": "[[category]]<br><b><span style='font-size:14px;'>[[value]]</span></b>",
                            "bullet": "round",
                            "bulletSize": 5,
                            "lineThickness": 2,
                            "negativeLineColor": "#637bb6",
                            "type": "smoothedLine",
                            "title": "V Batt",
                            "valueField": "vbatt"
                        },
                        {
                            "id":"ibatt",
                            "balloonText": "[[category]]<br><b><span style='font-size:14px;'>[[value]]</span></b>",
                            "bullet": "round",
                            "bulletSize": 5,  
                            "lineThickness": 2,
                            "negativeLineColor": "#637bb6",
                            "type": "smoothedLine",
                            "title": "I Batt",
                            "valueField": "ibatt"
                        },
                        {
                            "id":"iload",
                            "balloonText": "[[category]]<br><b><span style='font-size:14px;'>[[value]]</span></b>",
                            "bullet": "round",
                            "bulletSize": 5,
                            "lineThickness": 2,
                            "negativeLineColor": "#637bb6",
                            "type": "smoothedLine",
                            "title": "I Load",
                            "valueField": "iload"
                        },
                        {
                            "id":"temperature_ctrl",
                            "balloonText": "[[category]]<br><b><span style='font-size:14px;'>[[value]]</span></b>",
                            "bullet": "round",
                            "bulletSize": 5,
                            "lineThickness": 2,
                            "negativeLineColor": "#637bb6",
                            "type": "smoothedLine",
                            "title": "Temp Ctrl",
                            "valueField": "temperature_ctrl"
                        },
                        {
                            "id":"temperature_batt",
                            "balloonText": "[[category]]<br><b><span style='font-size:14px;'>[[value]]</span></b>",
                            "bullet": "round",
                            "bulletSize": 5,
                            "lineThickness": 2,
                            "negativeLineColor": "#637bb6",
                            "type": "smoothedLine",
                            "title": "Temp Batt",
                            "valueField": "temperature_batt"
                        }
                    ],
                    "chartScrollbar": {
                        "graph":"g1",
                        "gridAlpha":0,
                        "color":"#888888",
                        "scrollbarHeight":55,
                        "backgroundAlpha":0,
                        "selectedBackgroundAlpha":0.1,
                        "selectedBackgroundColor":"#888888",
                        "graphFillAlpha":0,
                        "autoGridCount":true,
                        "selectedGraphFillAlpha":0,
                        "graphLineAlpha":0.2,
                        "graphLineColor":"#c2c2c2",
                        "selectedGraphLineColor":"#888888",
                        "selectedGraphLineAlpha":1
                    },
                    "chartCursor": {
                        //"categoryBalloonDateFormat": "YYYY",
                        "cursorAlpha": 0,
                        "valueLineEnabled":true,
                        "valueLineBalloonEnabled":true,
                        "valueLineAlpha":0.5,
                        "fullWidth":true
                    },
                    //"dataDateFormat": "YYYY",
                    "categoryField": "jsdate",
                    "categoryAxis": {
                        "minPeriod": "mm",
                        "parseDates": true,
                        "minorGridAlpha": 0.1,
                        "minorGridEnabled": true
                    },
                    "legend": {
                        "align": "left",
                        "marginLeft": 110,
                        "color": "#000000"
                    },
                    "export": {
                        "enabled": true
                    },
                    "titles": [
                        {
                            "size": 14,
                            "text": currSite.name+" Performance"
                        }
                    ]
                });
          
            },'json');
            $('#table_out').hide();
            $('#chart_out').show();
        }
        
    }
}

function node_detail()
{
    window.location = BASE_URL+'node/view/'+currSite.id;
}

function node_save()
{
    bootbox.confirm("Do you want to save ?", function(res) {
        if(res) {
            $.post(BASE_URL+'api/node/save', $('#form_site').serialize(), function(result){
                if(result.success) {
                    if($('#id').val() == '') {
                        var id = parseInt(result.data);                        
                        point = new google.maps.LatLng(parseFloat($('#latitude').val()), parseFloat($('#longitude').val()));
                        tanda = new google.maps.Marker({position: point, map: map, draggable: true, icon: BASE_URL+'assets/images/lamp_grey.png' });
                        markers[id] = tanda;
                        var site = {};
                        $.get(BASE_URL+'api/node/info/'+id, {}, function(data){ site = data; });
                        node_create(tanda, site);
                    }
                    $('#frmSiteDlg').modal('hide');
                }
                else bootbox.alert(result.msg);
            },'json');
        }
    });
}

function node_turn_all(cmd)
{
    $('.contextmenu').remove();
    bootbox.confirm("Do you want to "+cmd+" all site ?", function(res) {
        if(res) {
            $.post(BASE_URL+'api/node/turn', {command:cmd}, function(result){
                bootbox.alert(result.msg);
            },'json');
        }
    });
}

function node_delete_all()
{
    $('.contextmenu').remove();
    bootbox.confirm("Do you want to remove all site ?", function(res) {
        if(res) {
            $.post(BASE_URL+'api/node/clear', {}, function(result){
                bootbox.alert(result.msg);
            },'json');
        }
    });
}

function node_master_show(node_id)
{
    $.get(BASE_URL+'api/node/info/'+node_id, {}, function(res){ 
        msg = res.data; 
        $('#title_consen').html('PJU Summary - '+msg.name+' - '+msg.subnet); 
    },'json');
    
    $.get(BASE_URL+'api/node/child/'+node_id, {}, function(msg){
        var table = $('#tableconsen').DataTable();
        table.clear().draw();                            
        for(var i=0; i<msg.rows.length; i++)
        {
            status = 'OFF';
            if(msg.rows[i].status == '1' && parseFloat(msg.rows[i].iload) > 1) status = 'ON';
            else if(msg.rows[i].status == '1' && parseFloat(msg.rows[i].iload) < 1) status = 'STANDBY';
            
            table.row.add([
                msg.rows[i].name,
                status,
                msg.rows[i].vbatt,
                msg.rows[i].ibatt,
                msg.rows[i].iload,
                msg.rows[i].temperature_ctrl,
                msg.rows[i].temperature_batt,
                msg.rows[i].updated_at
            ]).draw();
        }
    },'json');
    $('#frmConsenDlg').modal('show');
}

function getCanvasXY(currentLatLng)
{
    var scale = Math.pow(2, map.getZoom());
    var nw = new google.maps.LatLng(
        map.getBounds().getNorthEast().lat(),
        map.getBounds().getSouthWest().lng()
    );
    var worldCoordinateNW = map.getProjection().fromLatLngToPoint(nw);
    var worldCoordinate = map.getProjection().fromLatLngToPoint(currentLatLng);
    var currentLatLngOffset = new google.maps.Point(
        Math.floor((worldCoordinate.x - worldCoordinateNW.x) * scale),
        Math.floor((worldCoordinate.y - worldCoordinateNW.y) * scale)
    );
    return currentLatLngOffset;
}

function setMenuXY(currentLatLng)
{
    var mapWidth = $('#map').width();
    var mapHeight = $('#map').height();
    var menuWidth = $('.contextmenu').width();
    var menuHeight = $('.contextmenu').height();
    var clickedPosition = getCanvasXY(currentLatLng);
    var x = clickedPosition.x - 20;
    var y = clickedPosition.y - 40;
    
    if((mapWidth - x ) < menuWidth) x = x - menuWidth;
    if((mapHeight - y ) < menuHeight) y = y - menuHeight;
    
    $('.contextmenu').css('left', x);
    $('.contextmenu').css('top', y);
};

function showContextMenu(event)
{
    var projection;
    projection = map.getProjection() ;
    $('.contextmenu').remove();
    contextmenuDir = document.createElement("div");
    contextmenuDir.className    = 'contextmenu';
    
    if(ROLE_ID == '1' || ROLE_ID == '2')
    {
        contextmenuDir.innerHTML    = '<div class="context" onclick="node_add()">New Site<\/div>';    
        contextmenuDir.innerHTML    += '<div class="separator"><\/div>';
        //contextmenuDir.innerHTML    += '<div class="context" onclick="node_turn_all(\'ON\')">Turn ON All<\/div>';
        //contextmenuDir.innerHTML    += '<div class="context" onclick="node_turn_all(\'OFF\')">Turn OFF All<\/div>';
        contextmenuDir.innerHTML    += '<div class="context" onclick="node_delete_all()">Remove All<\/div>';
    }    
    //else contextmenuDir.innerHTML   = '';
    
    $(map.getDiv()).append(contextmenuDir);      
    setMenuXY(event.latLng);
    contextmenuDir.style.visibility = "visible";
}

function rightMenu(event, site)
{
    currSite = site;
    var projection;
    projection = map.getProjection() ;
    $('.contextmenu').remove();
    
    contextmenuDir              = document.createElement("div");
    contextmenuDir.className    = 'contextmenu';
    contextmenuDir.innerHTML    = '';
    if(ROLE_ID == '1' || ROLE_ID == '2')
    {
        contextmenuDir.innerHTML    += '<div class="context" onclick="node_edit()">Edit<\/div>';
        contextmenuDir.innerHTML    += '<div class="context" onclick="node_delete()">Delete<\/div>';
        contextmenuDir.innerHTML    += '<div class="separator"><\/div>';
    }
    contextmenuDir.innerHTML    += '<div class="context" onclick="node_detail()">Monitoring<\/div>';
    contextmenuDir.innerHTML    += '<div class="context" onclick="node_datalog()">Data log<\/div>';
    contextmenuDir.innerHTML    += '<div class="context" onclick="node_alarmlog()">Alarm log<\/div>';
    
    $(map.getDiv()).append(contextmenuDir);
    
    setMenuXY(event.latLng);
    contextmenuDir.style.visibility = "visible";
}

function node_create(tanda, site)
{
    google.maps.event.addListener(tanda, 'mouseover', function(event) {
        //map.setZoom(15);
        //map.setCenter(tanda.getPosition());
        var label = '<table>';
        label   += '<tr><td colspan="2"><strong>'+site.subnet+' - '+site.name+'</strong></td></tr>';
        
        label   += '<tr><td>Genset Voltage</td> <td>: ' + site.genset_vr + ' | '+site.genset_vs+' | '+site.genset_vt+' V</td></tr>';
        label   += '<tr><td>Genset Current</td> <td>: ' + site.genset_cr + ' | '+site.genset_cs+' | '+site.genset_ct+' A</td></tr>';
        label   += '<tr><td>Batt Voltage</td> <td>: ' + site.batt_volt + ' V</td></tr>';
        label   += '<tr><td>Batt Current</td> <td>: ' + site.batt_curr + ' A</td></tr>';
        label   += '<tr><td>Genset Batt Voltage</td> <td>: ' + site.genset_batt_volt + ' V</td></tr>';        
        
        label   += '<tr><td>Updated</td> <td>: ' + site.updated_at + ' WIB</td></tr>';
        label   += '</table>';
        
        infoWindow.setContent(label);
        infoWindow.open(map, tanda);
    });
    google.maps.event.addListener(tanda, 'mouseout', function(event) { infoWindow.close(); });
    google.maps.event.addListener(tanda, 'click', function(event){ window.location = BASE_URL+'node/view/'+site.id; });
    google.maps.event.addListener(tanda, 'rightclick', function(event) {
        //console.log(event.latLng.lat()+ " : " +event.latLng.lng());
        rightMenu(event, site);
    });
    google.maps.event.addListener(tanda, 'dragend', function(event){ 
        $.post(BASE_URL+'api/site/latlng', {id:site.id, lat:event.latLng.lat(), lng:event.latLng.lng()}, function(result){
            //console.log('move to : '+ event.latLng.lat()+ " : " +event.latLng.lng() + " --> " +result.success);
        },'json');
    });
}

function node_load(url)
{
    $.ajax({
        url: url,
        dataType: 'json',
        cache: false,
        success: function(msg){
            for(i=0;i<msg.data.length;i++)
            {
                var site = msg.data[i];
                var point = new google.maps.LatLng(parseFloat(site.latitude), parseFloat(site.longitude));
                
                // off = grey, on = green                                
                if(site.genset_fail == '1' || site.low_fuel == '1' || site.recti_fail == '1' || site.batt_low == '1') tanda = new google.maps.Marker({position: point, map: map, draggable: true, icon: BASE_URL+'assets/images/lamp_red.png' });
                else tanda = new google.maps.Marker({position: point, map: map, draggable: true, icon: BASE_URL+'assets/images/lamp_green.png' });
                
                // remove marker previous
                if( markers[site.id] != null ) {
                    node = markers[site.id];
                    node.setMap(null);
                }

                // register marker to array markers
                markers[site.id] = tanda;
                node_create(tanda, site);
            }
        }
    });
}

function loadMap()
{
    var mapDiv  = document.getElementById('map');
    var mapOptions  = {
        center: new google.maps.LatLng(-6.95036864165453, 107.644547224045),
        zoom: 10,
        mapTypeId: google.maps.MapTypeId.ROADMAP
    };
    map = new google.maps.Map(mapDiv, mapOptions);
    google.maps.event.addListener(map, "click", function(event){ $('.contextmenu').remove(); });
    google.maps.event.addListener(map, "rightclick", function(event){
        lat = event.latLng.lat();
        lng = event.latLng.lng();
        //console.log("Lat=" + lat + "; Lng=" + lng);
        showContextMenu(event);
    });
    node_load(BASE_URL+'api/node/all');
}

//loadMap();