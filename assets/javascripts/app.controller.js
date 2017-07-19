'use strict';
/**
 * @ngdoc overview
 * @name cdcApp
 * @description
 * # cdcApp
 *
 * Controller module of the application.
 */
 angular.module('cdcApp')
    .controller('HeaderController', ['$rootScope', '$interval', '$scope', '$modal', '$location', '$http', function($rootScope, $interval, $scope, $modal, $location, $http){
        
        $scope.site = null;
        
        $('#typeahead').typeahead(
    	{
            minLength: 2,
            items: 4,
            source: function(query, process){
                $.ajax({
                    url: BASE_URL+'api/node/search',
                    data: {q: query},
                    dataType: 'json'
                })
                .done(function(response) {
                    console.log(response);
                    return process(response);
                });
            },
            autoSelect: true,
            displayText: function(item){ return item.name;},
            afterSelect: function(item) {
                $scope.site = item;
                console.log(item);
                $location.path('/node/view/'+item.id); 
            }
        });
        
        $scope.gosite       = function() {
            if($scope.site != null) $location.path('/node/view/'+site.id);
        }
        
        $scope.userinfo = {};
        
        $http.get(BASE_URL+'api/user/info').success(function(response){
            $scope.userinfo = response;
            userInfo = $scope.userinfo;
            //console.log(userInfo);
        });
        
        $scope.sites    = [];
        $http.get(BASE_URL+'api/node/all').success(function(response){
            $scope.sites = response;
        });
        
        $scope.displayText = function(item) {
            return item.name;
        }
        
        $scope.afterSelect = function(item) {
            alert(item.id);
        }
        
        $scope.getSite  = function(siteName) {
            return $http.get(BASE_URL+'api/node/all').then(function(response){
                return response.data.map(function(item){
                    return item.name;
                });
            });
        }
        
        $scope.logout   = function() {
            bootbox.confirm("Are you sure to logout ?", function(result) {
                if(result) {
                    $http.get(BASE_URL+'api/auth/logout').success(function(data){
                        window.location.href = BASE_URL + 'login';
                    });
                }
            });
        }
          
        $scope.openPopUp = function (o, s) {
            var modalInstance = $modal.open({
                templateUrl: BASE_URL+'assets/pages/alarmPopup.html',
                controller: 'AlarmPopupController',
                size: s,
                resolve: {
                    item: function() {
                        return o;
                    }
                }
            });
            
            modalInstance.result.then(function(selectedObject) {
                isOpened = false;
                console.log(isOpened);
            });
        }
        
        $rootScope.popupTimer = $interval(function () {
            if(userInfo.popup_enabled == '1') {
                $http.get(BASE_URL+'api/alarm/total').success(function(total){
                    if(parseInt(total) > 0) {
                        if(!isOpened) {
                            //console.log(isOpened);
                            isOpened = true;
                            $scope.openPopUp(null);
                            //console.log(isOpened);
                        }
                    }
                });
            }
        }, 10*1000);
        
    }])
    .controller('AlarmPopupController', function($scope, $modalInstance, $http){
        
        $scope.alarms   = {};
        
        $scope.reload = function() {
            $http.get(BASE_URL+'api/alarm/fetch/all/_/_/_/_/1/100/0').success(function(response){
                $scope.alarms = response;
                $scope.alarms.pages = [];
                for(var i=0; i<$scope.alarms.totalPage; i++) $scope.alarms.pages[i] = i+1;
                for(var i=0; i<$scope.alarms.content.length; i++) {
                    if($scope.alarms.content[i].acknowledge == '1') $scope.alarms.content[i].selected = true;
                    else $scope.alarms.content[i].selected = false;
                }
            });
        }
        
        $scope.toggleAll = function() {
            var toggleStatus = !$scope.isAllSelected;
            angular.forEach($scope.alarms.content, function(itm){ itm.selected = toggleStatus; });
        }
        
        $scope.alarmToggled = function(){
            $scope.isAllSelected = $scope.alarms.content.every(function(itm){ return itm.selected; })
        }
        
        $scope.ackAll   = function() {
            $http.post(BASE_URL+'api/alarm/ack', $scope.alarms.content).success(function(response){
                $scope.cancel();
            });
        }
        
        $scope.delAll   = function() {
            $http.post(BASE_URL+'api/alarm/delete', $scope.alarms.content).success(function(response){
                $scope.cancel();
            });
        }
        
        $scope.cancel = function () {
            $modalInstance.dismiss('Close');
            isOpened = false;
        };
        
        $scope.reload();
    })
    .controller('HomeController', function($scope, $http, $interval, $location){        
        //$scope.devices = ['Node 1', 'Node 2', 'Node 3'];
        $scope.sactive = {};
        $scope.sites    = [];
        $http.get(BASE_URL+'api/node/all').success(function(sites){
            $scope.sites = sites;
        });

        $scope.open     = function(id) {
            $location.path('/node/view/'+id);
        }
    })
    .controller('MapController', function($rootScope, $interval, $scope, $http, $location, $timeout) {
        if (angular.isDefined($rootScope.alarmTimer)) $interval.cancel($rootScope.alarmTimer);
        if (angular.isDefined($rootScope.nodeTimer)) $interval.cancel($rootScope.nodeTimer);
        
        $scope.map;
        $scope.markers = [];
        $scope.infoWindow = new google.maps.InfoWindow();
        $scope.lat;
        $scope.lng;          
        $scope.contextMenuOptions={};
        $scope.contextMenuOptions.classNames={menu:'context_menu', menuSeparator:'context_menu_separator'};                
        $scope.menuItems=[];
        if(ROLE_ID == '1' || ROLE_ID == '2')
        {
            $scope.menuItems.push({className:'context_menu_item', eventName:'node_add', label:'New Site'});
            $scope.menuItems.push({className:'context_menu_item', eventName:'node_clear', label:'Remove All'});
            $scope.menuItems.push({});
        }
        $scope.menuItems.push({className:'context_menu_item', eventName:'zoom_in', label:'Zoom In'});
        $scope.menuItems.push({className:'context_menu_item', eventName:'zoom_out', label:'Zoom Out'});
        $scope.menuItems.push({className:'context_menu_item', eventName:'center_map', label:'Center Map Here'});
        
        $scope.contextMenuOptions.menuItems = $scope.menuItems;
        
        $scope.contextMenu;
        
        $scope.nodeLoad= function(url) {
            $http.get(url).success(function(data){
                for(var i=0;i<data.length;i++)
                {
                    var site = data[i];
                    var tanda= {};
                    var node = {};
                    var point = new google.maps.LatLng(parseFloat(site.latitude), parseFloat(site.longitude));
                    
                    // off = grey, on = green                                
                    if(site.genset_on_fail == '1' || site.genset_off_fail == '1' || site.low_fuel == '1' || site.recti_fail == '1' || site.batt_low == '1' || site.sin_high_temp == '1' || site.eng_high_temp == '1' || site.oil_pressure == '1') tanda = new google.maps.Marker({position: point, map: $scope.map, draggable: true, icon: BASE_URL+'assets/images/lamp_red.png' });
                    else if(site.opr_status_id == '3') tanda = new google.maps.Marker({position: point, map: $scope.map, draggable: true, icon: BASE_URL+'assets/images/lamp_grey.png' });
                    else tanda = new google.maps.Marker({position: point, map: $scope.map, draggable: true, icon: BASE_URL+'assets/images/lamp_green.png' });
                    
                    // remove marker previous
                    if( $scope.markers[site.id] != null ) {
                        node = $scope.markers[site.id];
                        node.setMap(null);
                    }
    
                    // register marker to array markers
                    $scope.markers[site.id] = tanda;
                    $scope.nodeCreate(tanda, site);
                }
            });
        }
        
        $scope.nodeCreate   = function(tanda, site)
        {
            google.maps.event.addListener(tanda, 'mouseover', function(event) {
                //map.setZoom(15);
                //map.setCenter(tanda.getPosition());
                var label = '<table>';
                label   += '<tr><td colspan="2"><strong>'+site.subnet+' - '+site.name+'</strong></td></tr>';

                label   += '<tr><td>Genset Voltage</td> <td>: ' + site.genset_vr + ' | '+site.genset_vs+' | '+site.genset_vt+' V</td></tr>';                
                label   += '<tr><td>Batt Voltage</td> <td>: ' + site.batt_volt + ' V</td></tr>';
                label   += '<tr><td>Genset Batt Voltage</td> <td>: ' + site.genset_batt_volt + ' V</td></tr>';        
                label   += '<tr><td>Running Hour </td> <td>: ' + site.run_hour + ' V</td></tr>';
                
                if (site.genset_on_fail == '1') label   += '<tr><td>Genset ON Fail</td> <td>: ACTIVE</td></tr>';
                if (site.genset_off_fail == '1')label   += '<tr><td>Genset OFF Fail</td> <td>: ACTIVE</td></tr>';
                if (site.low_fuel == '1')       label   += '<tr><td>Low Fuel</td> <td>: ACTIVE</td></tr>';
                if (site.recti_fail == '1')     label   += '<tr><td>Rectifier Fail</td> <td>: ACTIVE</td></tr>';
                if (site.batt_low == '1')       label   += '<tr><td>Batt Low Voltage</td> <td>: ACTIVE</td></tr>';
                if (site.sin_high_temp == '1')  label   += '<tr><td>SineGen High Temp</td> <td>: ACTIVE</td></tr>';
                if (site.eng_high_temp == '1')  label   += '<tr><td>Engine High Temp</td> <td>: ACTIVE</td></tr>';
                if (site.oil_pressure == '1')   label   += '<tr><td>Oil Pressure</td> <td>: ACTIVE</td></tr>';
                //if (site.maintain_status == '1')label   += '<tr><td>Maintenance Mode</td> <td>: ACTIVE</td></tr>';
                
                label   += '<tr><td>Status</td> <td>: ' + site.status+'</td></tr>';
                
                if(site.opr_status_id != '3')
                {
                    // genset on
                    if(site.genset_status == '1') label   += '<tr><td>Next Off</td> <td>: ' + site.next_off + ' WIB</td></tr>';
                    // next on
                    else label   += '<tr><td>Next On</td> <td>: ' + site.next_on + ' WIB</td></tr>';
                }
                
                label   += '<tr><td>Updated</td> <td>: ' + site.updated_at + ' WIB</td></tr>';
                label   += '</table>';
                
                $scope.infoWindow.setContent(label);
                $scope.infoWindow.open($scope.map, tanda);
            });
            google.maps.event.addListener(tanda, 'mouseout', function(event) { $scope.infoWindow.close(); });
            google.maps.event.addListener(tanda, 'click', function(event){ 
                $scope.$apply(function(){ $location.path('/node/view/'+site.id); });
            });
            google.maps.event.addListener(tanda, 'rightclick', function(event) {
                //$scope.nodeClear();
            });
            google.maps.event.addListener(tanda, 'dragend', function(event){ 
                $.post(BASE_URL+'api/site/latlng', {id:site.id, lat:event.latLng.lat(), lng:event.latLng.lng()}, function(result){
                    //console.log('move to : '+ event.latLng.lat()+ " : " +event.latLng.lng() + " --> " +result.success);
                },'json');
            });
        }
        
        $scope.nodeAdd = function() {
            $scope.currSite = null;
            $('#form_site').resetForm();
            $('#dlg_title_site').html('Add New Site');       
            
            $.get(BASE_URL+'api/subnet/all', {},function(result){
                $('#subnet_id').find('option').remove().end().append('<option value="">- Select -</option>');
                for(var i=0; i<result.length; i++) $('#subnet_id').append($("<option></option>").attr("value",result[i].id).text(result[i].name));
            },'json');
            
            $.get(BASE_URL+'api/customer/all', {},function(result){
                $('#customer_id').find('option').remove().end().append('<option value="">- Select -</option>');
                for(var i=0; i<result.length; i++) $('#customer_id').append($("<option></option>").attr("value",result[i].id).text(result[i].name));        
            },'json');
            
            $('#latitude').val($scope.lat);
            $('#longitude').val($scope.lng);
            $('#frmSiteDlg').modal('show');
        }
        
        $scope.nodeSave = function() {
            var site    = {};
            
            $http.post(BASE_URL+'api/user/save', site).then(function (result) {
                $('#frmSiteDlg').modal('hide');
            });
        }
        
        $scope.nodeClear = function() {
            alert('Disabled');
        }
        
        $timeout(function(){
            var mapDiv  = document.getElementById('map');
            var mapOptions  = {
                center: new google.maps.LatLng(-6.95036864165453, 107.644547224045),
                zoom: 6,
                mapTypeId: google.maps.MapTypeId.ROADMAP
            };
            $scope.map = new google.maps.Map(mapDiv, mapOptions);
            $scope.contextMenu = new ContextMenu($scope.map, $scope.contextMenuOptions);
            google.maps.event.addListener($scope.map, "click", function(event){ $('.contextmenu').remove(); });
            google.maps.event.addListener($scope.map, "rightclick", function(event){
                $scope.lat = event.latLng.lat();
                $scope.lng = event.latLng.lng();
                //console.log("Lat=" + lat + "; Lng=" + lng);                
                $scope.contextMenu.show(event.latLng);
            });
            google.maps.event.addListener($scope.contextMenu, 'menu_item_selected', function(latLng, eventName){
                switch(eventName) {
                    case 'node_add':
                        $scope.nodeAdd();
                        break;
                    case 'node_clear':
                        $scope.nodeClear();
                        break;
                    case 'zoom_in':
                        $scope.map.setZoom($scope.map.getZoom()+1);
                        break;
        			case 'zoom_out':
                        $scope.map.setZoom($scope.map.getZoom()-1);
                        break;
        			case 'center_map':
                        $scope.map.panTo(latLng);
                        break;
                }
            });
            
            $scope.nodeLoad(BASE_URL+'api/node/all');
            
            $rootScope.Timer = $interval(function () {
                $scope.nodeLoad(BASE_URL+'api/node/all');
            }, 15*1000);
            
        },100);
        
    })
    .controller('NodeController', function($rootScope, $interval, $scope, $timeout, $q, $http, $stateParams, AlarmService){
        if (angular.isDefined($rootScope.Timer)) $interval.cancel($rootScope.Timer);        
        if (angular.isDefined($rootScope.alarmTimer)) $interval.cancel($rootScope.alarmTimer);
        $("#startDate").datepicker({todayHighlight: true, format:'yyyy-mm-dd'});
        $("#stopDate").datepicker({todayHighlight: true, format:'yyyy-mm-dd'});
        $("#startDateAlarm").datepicker({todayHighlight: true, format:'yyyy-mm-dd'});
        $("#stopDateAlarm").datepicker({todayHighlight: true, format:'yyyy-mm-dd'});
        $("#startDateSMS").datepicker({todayHighlight: true, format:'yyyy-mm-dd'});
        $("#stopDateSMS").datepicker({todayHighlight: true, format:'yyyy-mm-dd'});
        
        $scope.node = {};
        $scope.node.lf  = 'low_fuel_off.png';
        $scope.node.gs  = 'genset_on.png';
        $scope.node.bs  = 'breaker_on.png';
        $scope.node.rs  = 'recti_on.png';
        $scope.node.bl  = 'bts_load.png';
        $scope.node.bg  = 'batt_genset.png';
        $scope.node.lb  = 'low_batt_off.png';        
        
        $scope.reloadPage = function() {
            $http.get(BASE_URL+'api/node/info/'+$stateParams.id).success(function(data){
                $scope.node = data;
                $scope.node.lf  = (data.low_fuel == '1') ? 'low_fuel_on.png' : 'low_fuel_off.png';
                $scope.node.gs  = (data.genset_status == '1') ? 'genset_on.png' : 'genset_off.png';
                $scope.node.bs  = (data.recti_status == '1') ? 'breaker_on.png' : 'breaker_off.png';
                $scope.node.rs  = (data.recti_status == '1') ? 'recti_on.png' : 'recti_off.png';
                $scope.node.bl  = 'bts_load.png';
                $scope.node.bg  = 'batt_genset.png';
                $scope.node.lb  = (data.batt_low == '1') ? 'low_batt_on.png' : 'low_batt_off.png';
            });
        }
        
        $scope.reloadPage();
        
        $scope.itemPerPages = [10, 20, 30];
        $scope.itemPerPage  = 10;
        $scope.alarms = [];
        $scope.reloadAlamPage = function(page){
            if(!page || page < 1) {
                page = 1;
            }  
            $http.get(BASE_URL+'api/alarm/node/'+$stateParams.id+'/'+page+'/'+$scope.itemPerPage).success(function(response){
                $scope.alarms = response;
                $scope.alarms.pages = [];
                for(var i=0; i<$scope.alarms.totalPage; i++) $scope.alarms.pages[i] = i+1;
            });
        }
        $scope.reloadAlamPage();
        
        $rootScope.nodeTimer = $interval(function () {
            $scope.reloadPage();
            $scope.reloadAlamPage();
        }, 15*1000);
            
        // data log
        $scope.amChartOptions = {};
        $scope.dataFromPromise;
        $scope.mode         = 'table';
        $scope.datalogs     = [];
        $scope.viewDatalog  = function(mode) {
            //alert(mode);
            $scope.mode     = mode;
            if(mode == 'xls') window.open(BASE_URL+'api/datalog/site/'+$stateParams.id+'/'+$('#startDate').val()+'/'+$('#stopDate').val()+'/xls');
            else {
                $http.get(BASE_URL+'api/datalog/site/'+$stateParams.id+'/'+$('#startDate').val()+'/'+$('#stopDate').val()+'/json').success(function(response){
                    $scope.datalogs = response;
                });
                if(mode == 'chart') {
                    for(var i=0; i<$scope.datalogs.length; i++) {
                        $scope.datalogs[i].jsdate = new Date($scope.datalogs[i].jsdate);
                    }
                    
                    $scope.dataFromPromise = function(){
                        var deferred = $q.defer();
                        var data = $scope.datalogs;
                        deferred.resolve(data)
                        return deferred.promise;
                    };
                    
                    $scope.amChartOptions = $timeout(function(){
                        return {
                            data: $scope.dataFromPromise(),
                            type: "serial",
                            theme: "light",
                            categoryField: "jsdate",                        
                            pathToImages: BASE_URL+'assets/javascripts/amcharts/dist/images/',
                            legend: {
                                enabled: true
                            },
                            chartScrollbar: {
                                enabled: true,
                            },
                            categoryAxis: {
                                minPeriod: "mm",                            
                                parseDates: true
                            },
                            valueAxes: [{
                                position: "left",
                                title: "Value"
                            }],
                            graphs: [{
                                    type: "smoothedLine",
                                    title: "Genset Voltage R",
                                    valueField: "genset_vr",
                                    lineThickness: 1,
                                    bullet: "round",
                                    bulletSize: 3,
                                    negativeLineColor: "#637bb6"
                                },{
                                    type: "smoothedLine",
                                    title: "Genset Voltage S",
                                    valueField: "genset_vs",
                                    lineThickness: 1,
                                    bullet: "round",
                                    bulletSize: 3,
                                    negativeLineColor: "#637bb6"
                                },{
                                    type: "smoothedLine",
                                    title: "Genset Voltage T",
                                    valueField: "genset_vt",
                                    lineThickness: 1,
                                    bullet: "round",
                                    bulletSize: 3,
                                    negativeLineColor: "#637bb6"
                                },{
                                    type: "smoothedLine",
                                    title: "Batt Voltage",
                                    valueField: "batt_volt",
                                    lineThickness: 1,
                                    bullet: "round",
                                    bulletSize: 3,
                                    negativeLineColor: "#637bb6"
                                },{
                                    type: "smoothedLine",
                                    title: "Genset Batt Voltage",
                                    valueField: "genset_batt_volt",
                                    lineThickness: 1,
                                    bullet: "round",
                                    bulletSize: 3,
                                    negativeLineColor: "#637bb6"
                                }]
                        }
                    }, 1000);                    
                }
            }            
        }
        
        // alarmlog
        $scope.alarmlogs    = [];
        $scope.viewAlarmlog = function(mode) {            
            $scope.mode     = mode;
            if(mode == 'xls') window.open(BASE_URL+'api/alarmlog/site/'+$stateParams.id+'/'+$('#startDateAlarm').val()+'/'+$('#stopDateAlarm').val()+'/xls');
            else {
                $http.get(BASE_URL+'api/alarmlog/site/'+$stateParams.id+'/'+$('#startDateAlarm').val()+'/'+$('#stopDateAlarm').val()+'/json').success(function(response){
                    $scope.alarmlogs = response;
                });
                
            }            
        }
        
        // sms log
        $scope.smslogs    = [];
        $scope.viewSMS = function(mode) {            
            $scope.mode     = mode;
            if(mode == 'xls') window.open(BASE_URL+'api/smslog/site/'+$stateParams.id+'/'+$('#startDateSMS').val()+'/'+$('#stopDateSMS').val()+'/xls');
            else {
                $http.get(BASE_URL+'api/smslog/site/'+$stateParams.id+'/'+$('#startDateSMS').val()+'/'+$('#stopDateSMS').val()+'/json').success(function(response){
                    $scope.smslogs = response;
                });
            }            
        }
        
        // maintenance
        $scope.commands    = [];
        $http.get(BASE_URL+'api/command/list').success(function(response){
            $scope.commands = response;
        });
        
        $scope.cmdlogs  = [];
        $http.get(BASE_URL+'api/cmdlog/site/'+$stateParams.id).success(function(response){
            $scope.cmdlogs = response;
        });
        
        $scope.send  = function(o) {
            bootbox.alert($('#form_sms').serialize());
            /*
            $http.post(BASE_URL+'api/cmdlog/save', $('#form_sms').serialize()).success(function (result) {
                
            });
            */
        }
        
        // Setting
        $scope.saveBatt  = function(batt) {
            bootbox.confirm("Do you want to save ? ", function(result){ 
                if(result) {
                    $http.post(BASE_URL+'api/site/update/'+$stateParams.id, batt).success(function(response){ });
                }
            });
        }
    })
    .controller('SummaryController', function($rootScope, $scope, $interval, $http, $timeout, $q){
        if (angular.isDefined($rootScope.Timer)) $interval.cancel($rootScope.Timer);
        if (angular.isDefined($rootScope.alarmTimer)) $interval.cancel($rootScope.alarmTimer);
        if (angular.isDefined($rootScope.nodeTimer)) $interval.cancel($rootScope.nodeTimer);
        
        $scope.connections  = [];
        $scope.severities   = [];
        
        $http.get(BASE_URL+'api/subnet/statistic').success(function(response){
            $scope.connections = response;
        });
        
        $http.get(BASE_URL+'api/alarm/statistic').success(function(response){
            $scope.severities = response;
        });        
            
        $timeout(function(){
            
            AmCharts.makeChart( "conn_chart", {
                "theme": "light",
                "type": "serial",
                "dataProvider": $scope.connections,
                "categoryField": "label",
                "categoryAxis": {
                    "gridPosition": "start"
                },
                "valueAxes": [ {
                    "title": "Total"
                } ],
                "graphs": [ {
                    "valueField": "value",
                    //"colorField": "color",
                    "type": "column",
                    "lineAlpha": 0.1,
                    "fillAlphas": 1
                } ],
                "chartCursor": {
                    "cursorAlpha": 0,
                    "zoomable": false,
                    "categoryBalloonEnabled": false
                }
            } );
            
            AmCharts.makeChart( "severity_chart", {
                "theme": "light",
                "type": "serial",
                "dataProvider": $scope.severities,
                "categoryField": "name",
                "categoryAxis": {
                    "gridPosition": "start"
                },
                "valueAxes": [ {
                    "title": "Total"
                } ],
                "graphs": [ {
                    "valueField": "total",
                    "colorField": "color",
                    "type": "column",
                    "lineAlpha": 0.1,
                    "fillAlphas": 1
                } ],
                "chartCursor": {
                    "cursorAlpha": 0,
                    "zoomable": false,
                    "categoryBalloonEnabled": false
                }
            } );
            
        }, 2000);
    })
    .controller('SurveillanceController', function($rootScope, $scope, $interval, $http){
        if (angular.isDefined($rootScope.Timer)) $interval.cancel($rootScope.Timer);
        if (angular.isDefined($rootScope.nodeTimer)) $interval.cancel($rootScope.nodeTimer);
        
        $("#startDate").datepicker({todayHighlight: true, format:'yyyy-mm-dd'});
        $("#stopDate").datepicker({todayHighlight: true, format:'yyyy-mm-dd'});
        $("#startDate").val(new Date().toJSON().slice(0,10));
        $("#stopDate").val(new Date().toJSON().slice(0,10));
        
        $scope.regions          = [];
        $scope.areas            = [];
        $scope.sites            = [];
        $scope.alarmLists       = [];        
        $scope.selectedRegion   = [];        
        $scope.selectedArea     = [];
        $scope.selectedSite     = [];        
        $scope.selectedAlarm    = [];
        $scope.actives          = {};
        $scope.actives.pages    = [];
        $scope.itemPerPages     = [10, 20, 30];
        $scope.itemPerPage      = 10;
        
        $http.get(BASE_URL+'api/subnet/region').success(function(response){
            $scope.regions = response;
        });
        $http.get(BASE_URL+'api/alarmList/all').success(function(response){
            $scope.alarmLists = response;
        });
        
        $scope.updateSelectedRegion = function($event, id){
            var checkbox = $event.target;
            if(checkbox.checked  && $scope.selectedRegion.indexOf(id) < 0){
                $scope.selectedRegion.push(id);
            } else {
                $scope.selectedRegion.splice($scope.selectedRegion.indexOf(id), 1);                
            }
            var region_id = '_';
            for(var i=0; i<$scope.selectedRegion.length; i++) {
                region_id += $scope.selectedRegion[i] + '_';                
            }
            if(region_id.length > 1) {
                region_id = region_id.substring(1, region_id.length - 1);
                $http.get(BASE_URL+'api/subnet/area/'+region_id).success(function(response){
                    $scope.areas = response;
                });
            }
            else {
                $scope.areas = [];
                $scope.sites = [];
            }          
        }
        
        $scope.updateSelectedArea = function($event, id){
            var checkbox = $event.target;
            if(checkbox.checked  && $scope.selectedArea.indexOf(id) < 0){
                $scope.selectedArea.push(id);
            } else {
                $scope.selectedArea.splice($scope.selectedArea.indexOf(id), 1);                
            }
            var area_id = '_';
            for(var i=0; i<$scope.selectedArea.length; i++) {
                area_id += $scope.selectedArea[i] + '_';                
            }
            if(area_id.length > 1) {
                area_id = area_id.substring(1, area_id.length - 1);
                $http.get(BASE_URL+'api/node/site/'+area_id).success(function(response){
                    $scope.sites = response;
                });
            }
            else {
                $scope.sites = [];
            }          
        }
        
        $scope.updateSelectedSite = function($event, id){
            var checkbox = $event.target;
            if(checkbox.checked  && $scope.selectedSite.indexOf(id) < 0){
                $scope.selectedSite.push(id);
            } else {
                $scope.selectedSite.splice($scope.selectedSite.indexOf(id), 1);                
            }
            var node_id = '_';
            for(var i=0; i<$scope.selectedSite.length; i++) {
                node_id += $scope.selectedSite[i] + '_';                
            }
            if(node_id.length > 1) node_id = node_id.substring(1, node_id.length - 1);
            else $scope.nodes = [];     
        }
        
        $scope.selectAllRegion = function($event){
            if($event.target.checked){
                for ( var i = 0; i < $scope.regions.length; i++) {
                    var p = $scope.regions[i];
                    if($scope.selectedRegion.indexOf(p.id) < 0){
                        $scope.selectedRegion.push(p.id);
                    }
                }
            } else {
                $scope.selectedRegion = [];
            }
        }
        
        $scope.updateSelectedAlarm = function($event, id){
            var checkbox = $event.target;
            if(checkbox.checked  && $scope.selectedAlarm.indexOf(id) < 0){
                $scope.selectedAlarm.push(id);
            } else {
                $scope.selectedAlarm.splice($scope.selectedAlarm.indexOf(id), 1);                
            }
        }
        
        $scope.buildAlarmUrl    = function() {
            var from    = $("#startDate").val();
            var to      = $("#stopDate").val();
            var alarm_id  = '_';
            for(var i=0; i<$scope.selectedAlarm.length; i++) alarm_id += $scope.selectedAlarm[i]+'_';
            if(alarm_id.length > 1) alarm_id = alarm_id.substring(1, alarm_id.length - 1);
            
            var node_id = '_';
            for(var i=0; i<$scope.selectedSite.length; i++) node_id += $scope.selectedSite[i]+'_';
            if(node_id.length > 1) node_id = node_id.substring(1, node_id.length - 1);
            
            var area_id = '_';
            for(var i=0; i<$scope.selectedArea.length; i++) area_id += $scope.selectedArea[i]+'_';
            if(area_id.length > 1) area_id = area_id.substring(1, area_id.length - 1);
            
            var region_id = '_';
            for(var i=0; i<$scope.selectedRegion.length; i++) region_id += $scope.selectedRegion[i]+'_';
            if(region_id.length > 1) region_id = region_id.substring(1, region_id.length - 1);
            
            if(node_id != '_') return BASE_URL+'api/alarm/fetch/site/'+node_id+'/'+alarm_id+'/'+from+'/'+to;
            else if(area_id != '_') return BASE_URL+'api/alarm/fetch/area/'+area_id+'/'+alarm_id+'/'+from+'/'+to;
            else if(region_id != '_') return BASE_URL+'api/alarm/fetch/region/'+region_id+'/'+alarm_id+'/'+from+'/'+to;
            else return BASE_URL+'api/alarm/fetch/all/_/'+alarm_id+'/'+from+'/'+to;
        }
                
        $scope.viewAlarm    = function(doc) {
            if(doc == 'xls') window.open($scope.buildAlarmUrl()+'/1/100/_/xls');
            else $scope.reloadAlamPage();
            //alert($scope.buildAlarmUrl());            
        }
        
        $scope.reloadAlamPage = function(page){
            if(!page || page < 1) {
                page = 1;
            }
            $http.get($scope.buildAlarmUrl()+'/'+page+'/'+$scope.itemPerPage+'/_').success(function(response){
                $scope.actives = response;
                $scope.actives.pages = [];
                for(var i=0; i<$scope.actives.totalPage; i++) $scope.actives.pages[i] = i+1;
            });
        }
        
        $scope.reloadAlamPage();
        
        $rootScope.alarmTimer = $interval(function () {
            $scope.reloadAlamPage();
        }, 15*1000);

    })
    .controller('AlarmLogController', function($rootScope, $scope, $filter, $interval, $http){
        if (angular.isDefined($rootScope.Timer)) $interval.cancel($rootScope.Timer);
        if (angular.isDefined($rootScope.alarmTimer)) $interval.cancel($rootScope.alarmTimer);
        if (angular.isDefined($rootScope.nodeTimer)) $interval.cancel($rootScope.nodeTimer);
        
        $("#startDate").datepicker({todayHighlight: true, format:'yyyy-mm-dd'});
        $("#stopDate").datepicker({todayHighlight: true, format:'yyyy-mm-dd'});
        $("#startDate").val(new Date().toJSON().slice(0,10));
        $("#stopDate").val(new Date().toJSON().slice(0,10));
        
        $scope.regions          = [];
        $scope.areas            = [];
        $scope.sites            = [];
        $scope.alarmLists       = [];        
        $scope.selectedRegion   = [];        
        $scope.selectedArea     = [];
        $scope.selectedSite     = [];
        $scope.selectedAlarm    = [];
        $scope.alarmlogs        = {};
        
        $http.get(BASE_URL+'api/subnet/region').success(function(response){
            $scope.regions = response;
        });
        $http.get(BASE_URL+'api/alarmList/all').success(function(response){
            $scope.alarmLists = response;
        });
        
        $scope.updateSelectedRegion = function($event, id){
            var checkbox = $event.target;
            if(checkbox.checked  && $scope.selectedRegion.indexOf(id) < 0){
                $scope.selectedRegion.push(id);
            } else {
                $scope.selectedRegion.splice($scope.selectedRegion.indexOf(id), 1);                
            }
            var region_id = '_';
            for(var i=0; i<$scope.selectedRegion.length; i++) {
                region_id += $scope.selectedRegion[i] + '_';                
            }
            if(region_id.length > 1) {
                region_id = region_id.substring(1, region_id.length - 1);
                $http.get(BASE_URL+'api/subnet/area/'+region_id).success(function(response){
                    $scope.areas = response;
                });
            }
            else {
                $scope.areas = [];
                $scope.sites = [];
            }          
        }
        
        $scope.updateSelectedArea = function($event, id){
            var checkbox = $event.target;
            if(checkbox.checked  && $scope.selectedArea.indexOf(id) < 0){
                $scope.selectedArea.push(id);
            } else {
                $scope.selectedArea.splice($scope.selectedArea.indexOf(id), 1);                
            }
            var area_id = '_';
            for(var i=0; i<$scope.selectedArea.length; i++) {
                area_id += $scope.selectedArea[i] + '_';                
            }
            if(area_id.length > 1) {
                area_id = area_id.substring(1, area_id.length - 1);
                $http.get(BASE_URL+'api/node/site/'+area_id).success(function(response){
                    $scope.sites = response;
                });
            }
            else {
                $scope.sites = [];
            }          
        }
        
        $scope.updateSelectedSite = function($event, id){
            var checkbox = $event.target;
            if(checkbox.checked  && $scope.selectedSite.indexOf(id) < 0){
                $scope.selectedSite.push(id);
            } else {
                $scope.selectedSite.splice($scope.selectedSite.indexOf(id), 1);                
            }
            var node_id = '_';
            for(var i=0; i<$scope.selectedSite.length; i++) {
                node_id += $scope.selectedSite[i] + '_';                
            }
            if(node_id.length > 1) node_id = node_id.substring(1, node_id.length - 1);
            else $scope.nodes = [];     
        }
        
        $scope.updateSelectedAlarm = function($event, id){
            var checkbox = $event.target;
            if(checkbox.checked  && $scope.selectedAlarm.indexOf(id) < 0){
                $scope.selectedAlarm.push(id);
            } else {
                $scope.selectedAlarm.splice($scope.selectedAlarm.indexOf(id), 1);                
            }
        }
        
        $scope.buildAlarmUrl    = function() {
            var from    = $("#startDate").val();
            var to      = $("#stopDate").val();
            
            var alarm_id  = '_';
            for(var i=0; i<$scope.selectedAlarm.length; i++) alarm_id += $scope.selectedAlarm[i]+'_';
            if(alarm_id.length > 1) alarm_id = alarm_id.substring(1, alarm_id.length - 1);
            
            var node_id = '_';
            for(var i=0; i<$scope.selectedSite.length; i++) node_id += $scope.selectedSite[i]+'_';
            if(node_id.length > 1) node_id = node_id.substring(1, node_id.length - 1);
            
            var area_id = '_';
            for(var i=0; i<$scope.selectedArea.length; i++) area_id += $scope.selectedArea[i]+'_';
            if(area_id.length > 1) area_id = area_id.substring(1, area_id.length - 1);
            
            var region_id = '_';
            for(var i=0; i<$scope.selectedRegion.length; i++) region_id += $scope.selectedRegion[i]+'_';
            if(region_id.length > 1) region_id = region_id.substring(1, region_id.length - 1);
            
            if(node_id != '_') return BASE_URL+'api/alarmlog/fetch/site/'+node_id+'/'+alarm_id+'/'+from+'/'+to;
            else if(area_id != '_') return BASE_URL+'api/alarmlog/fetch/area/'+site_id+'/'+alarm_id+'/'+from+'/'+to;
            else if(region_id != '_') return BASE_URL+'api/alarmlog/fetch/region/'+region_id+'/'+alarm_id+'/'+from+'/'+to;
            else return BASE_URL+'api/alarmlog/fetch/all/_/'+alarm_id+'/'+from+'/'+to;
        }
        
        $scope.viewAlarm    = function(doc) {
            if($scope.selectedRegion.length == 0) bootbox.alert("Please select region !");
            else if($scope.selectedArea.length == 0) bootbox.alert("Please select area !");
            else if($scope.selectedSite.length == 0) bootbox.alert("Please select site !");
            else {
                //bootbox.alert($scope.buildAlarmUrl()+'/'+doc);
                if(doc == 'xls') window.open($scope.buildAlarmUrl()+'/xls');
                else {
                    $http.get($scope.buildAlarmUrl()+'/'+doc).success(function(data){
                        $scope.alarmlogs = data;
                    });
                }
            }
        }
    })
    .controller('DataLogController', function($rootScope, $scope, $filter, $interval, $http, $timeout, $q){
        if (angular.isDefined($rootScope.Timer)) $interval.cancel($rootScope.Timer);
        if (angular.isDefined($rootScope.alarmTimer)) $interval.cancel($rootScope.alarmTimer);
        if (angular.isDefined($rootScope.nodeTimer)) $interval.cancel($rootScope.nodeTimer);
        
        $("#startDate").datepicker({todayHighlight: true, format:'yyyy-mm-dd'});
        $("#stopDate").datepicker({todayHighlight: true, format:'yyyy-mm-dd'});
        $("#startDate").val(new Date().toJSON().slice(0,10));
        $("#stopDate").val(new Date().toJSON().slice(0,10));
        
        $scope.regions          = [];
        $scope.areas            = [];
        $scope.sites            = [];
        $scope.selectedRegion   = [];        
        $scope.selectedArea     = [];
        $scope.selectedSite     = [];
        $scope.datalogs         = {};
        $scope.site             = {};
        $scope.mode             = 'table';
        
        $http.get(BASE_URL+'api/subnet/region').success(function(response){
            $scope.regions = response;
        });
        $http.get(BASE_URL+'api/alarmList/all').success(function(response){
            $scope.alarmLists = response;
        });
        
        $scope.updateSelectedRegion = function($event, id){
            var checkbox = $event.target;
            if(checkbox.checked  && $scope.selectedRegion.indexOf(id) < 0){
                $scope.selectedRegion.push(id);
            } else {
                $scope.selectedRegion.splice($scope.selectedRegion.indexOf(id), 1);                
            }
            var region_id = '_';
            for(var i=0; i<$scope.selectedRegion.length; i++) {
                region_id += $scope.selectedRegion[i] + '_';                
            }
            if(region_id.length > 1) {
                region_id = region_id.substring(1, region_id.length - 1);
                $http.get(BASE_URL+'api/subnet/area/'+region_id).success(function(response){
                    $scope.areas = response;
                });
            }
            else {
                $scope.areas = [];
                $scope.sites = [];
            }
            $scope.selectedArea     = [];
            $scope.selectedSite     = [];
        }
        
        $scope.updateSelectedArea = function($event, id){
            var checkbox = $event.target;
            if(checkbox.checked  && $scope.selectedArea.indexOf(id) < 0){
                $scope.selectedArea.push(id);
            } else {
                $scope.selectedArea.splice($scope.selectedArea.indexOf(id), 1);                
            }
            var area_id = '_';
            for(var i=0; i<$scope.selectedArea.length; i++) {
                area_id += $scope.selectedArea[i] + '_';                
            }
            if(area_id.length > 1) {
                area_id = area_id.substring(1, area_id.length - 1);
                $http.get(BASE_URL+'api/node/site/'+area_id).success(function(response){
                    $scope.sites = response;
                });
            }
            else {
                $scope.sites = [];
            }
            $scope.selectedSite     = [];
        }
        
        $scope.updateSelectedSite = function($event, id){
            var checkbox = $event.target;
            if(checkbox.checked  && $scope.selectedSite.indexOf(id) < 0){
                $scope.selectedSite.push(id);
            } else {
                $scope.selectedSite.splice($scope.selectedSite.indexOf(id), 1);                
            }
            var node_id = '_';
            for(var i=0; i<$scope.selectedSite.length; i++) {
                node_id += $scope.selectedSite[i] + '_';                
            }
            if(node_id.length > 1) node_id = node_id.substring(1, node_id.length - 1);
            else $scope.nodes = [];     
        }
        
        $scope.buildDataUrl    = function() {
            var from    = $("#startDate").val();
            var to      = $("#stopDate").val();
            
            var node_id = '_';
            for(var i=0; i<$scope.selectedSite.length; i++) node_id += $scope.selectedSite[i]+'_';
            if(node_id.length > 1) node_id = node_id.substring(1, node_id.length - 1);
            
            var area_id = '_';
            for(var i=0; i<$scope.selectedArea.length; i++) area_id += $scope.selectedArea[i]+'_';
            if(area_id.length > 1) area_id = area_id.substring(1, area_id.length - 1);
            
            var region_id = '_';
            for(var i=0; i<$scope.selectedRegion.length; i++) region_id += $scope.selectedRegion[i]+'_';
            if(region_id.length > 1) region_id = region_id.substring(1, region_id.length - 1);
            
            if(node_id != '_') return BASE_URL+'api/datalog/fetch/site/'+node_id+'/'+from+'/'+to;
            else if(area_id != '_') return BASE_URL+'api/datalog/fetch/area/'+site_id+'/'+from+'/'+to;
            else if(region_id != '_') return BASE_URL+'api/datalog/fetch/region/'+region_id+'/'+from+'/'+to;
            else return BASE_URL+'api/datalog/fetch/all/_/'+from+'/'+to;
        }
        
        $scope.viewData    = function(doc) {
            if($scope.selectedRegion.length == 0) bootbox.alert("Please select region !");
            else if($scope.selectedArea.length == 0) bootbox.alert("Please select area !");
            else if($scope.selectedSite.length == 0) bootbox.alert("Please select site !");
            else {
                //bootbox.alert($scope.buildDataUrl()+'/'+doc);
                $scope.mode = doc;
                if(doc == 'xls') window.open($scope.buildDataUrl()+'/xls');
                else {
                    $http.get($scope.buildDataUrl()+'/'+doc).success(function(data){
                        $scope.datalogs = data;
                    });
                    
                    if(doc == 'chart') {
                        for(var i=0; i<$scope.datalogs.length; i++) {
                            $scope.datalogs[i].jsdate = new Date($scope.datalogs[i].jsdate);
                        }
                        
                        $scope.dataFromPromise = function(){
                            var deferred = $q.defer();
                            var data = $scope.datalogs;
                            deferred.resolve(data)
                            return deferred.promise;
                        };
                        
                        $scope.amChartOptions = $timeout(function(){
                            return {
                                data: $scope.dataFromPromise(),
                                type: "serial",
                                theme: "light",
                                categoryField: "jsdate",                        
                                pathToImages: BASE_URL+'assets/javascripts/amcharts/dist/images/',
                                legend: {
                                    enabled: true
                                },
                                chartScrollbar: {
                                    enabled: true,
                                },
                                categoryAxis: {
                                    minPeriod: "mm",                            
                                    parseDates: true
                                },
                                valueAxes: [{
                                    position: "left",
                                    title: "Value"
                                }],
                                graphs: [{
                                    type: "smoothedLine",
                                    title: "Genset Voltage R",
                                    valueField: "genset_vr",
                                    lineThickness: 1,
                                    bullet: "round",
                                    bulletSize: 3,
                                    negativeLineColor: "#637bb6"
                                },{
                                    type: "smoothedLine",
                                    title: "Genset Voltage S",
                                    valueField: "genset_vs",
                                    lineThickness: 1,
                                    bullet: "round",
                                    bulletSize: 3,
                                    negativeLineColor: "#637bb6"
                                },{
                                    type: "smoothedLine",
                                    title: "Genset Voltage T",
                                    valueField: "genset_vt",
                                    lineThickness: 1,
                                    bullet: "round",
                                    bulletSize: 3,
                                    negativeLineColor: "#637bb6"
                                },{
                                    type: "smoothedLine",
                                    title: "Genset Batt Voltage",
                                    valueField: "genset_batt_volt",
                                    lineThickness: 1,
                                    bullet: "round",
                                    bulletSize: 3,
                                    negativeLineColor: "#637bb6"
                                },{
                                    type: "smoothedLine",
                                    title: "Batt Voltage",
                                    valueField: "batt_volt",
                                    lineThickness: 1,
                                    bullet: "round",
                                    bulletSize: 3,
                                    negativeLineColor: "#637bb6"
                                }]
                            }
                        }, 1000);                    
                    }
                
                }
            }
        }
    })
    .controller('ProfileController', function($rootScope, $scope, $filter, $interval, $http, $timeout, $q){
        if (angular.isDefined($rootScope.Timer)) $interval.cancel($rootScope.Timer);
        if (angular.isDefined($rootScope.alarmTimer)) $interval.cancel($rootScope.alarmTimer);
        if (angular.isDefined($rootScope.nodeTimer)) $interval.cancel($rootScope.nodeTimer);
        
        $scope.userinfo = {};
        
        $http.get(BASE_URL+'api/user/info').success(function(data){
            $scope.userinfo = data;
        });
        
        $scope.save = function(p){
            $http.post(BASE_URL+'api/user/update/'+p.id, p)
            .success(function (data, status, headers, config) {
                alert('succeed');
            })
            .error(function (data, status, header, config) {
                alert("Data: " + data +
                    "<hr />status: " + status +
                    "<hr />headers: " + header +
                    "<hr />config: " + config);
            });
        }   
    })
    .controller('SettingController', function($rootScope, $scope, $filter, $interval, $http, $timeout, $q){
        if (angular.isDefined($rootScope.Timer)) $interval.cancel($rootScope.Timer);
        if (angular.isDefined($rootScope.alarmTimer)) $interval.cancel($rootScope.alarmTimer);
        if (angular.isDefined($rootScope.nodeTimer)) $interval.cancel($rootScope.nodeTimer);
        
        $scope.setting  = null;
        $http.get(BASE_URL+'api/config/list').success(function(data){
            $scope.setting = data;
        });
        
        $scope.save     = function() {
            bootbox.confirm("Are you sure to change ?", function(result) {
                if(result) {
                    $http.post(BASE_URL+'api/config/update', $scope.setting).success(function(data){
                        
                    });
                }
            });
        }
    })
    .controller('CustomerController', function($rootScope, $scope, $modal, $filter, $interval, $http){
        if (angular.isDefined($rootScope.Timer)) $interval.cancel($rootScope.Timer);
        if (angular.isDefined($rootScope.alarmTimer)) $interval.cancel($rootScope.alarmTimer);
        if (angular.isDefined($rootScope.nodeTimer)) $interval.cancel($rootScope.nodeTimer);
        
        $scope.customer         = {};
        $scope.customers        = {};
        $scope.customers.pages  = [];
        $scope.itemPerPages     = [10, 20, 30];
        $scope.itemPerPage      = 10;
        
        $scope.open = function (p, s) {
            var modalInstance = $modal.open({
                templateUrl: BASE_URL+'assets/pages/customerEdit.html',
                controller: 'CustomerEditController',
                size: s,
                resolve: {
                    item: function() {
                        return p;
                    }
                }
            });
            
            modalInstance.result.then(function(selectedObject) {
                if(selectedObject.save == "insert"){
                    $scope.customers.content.push(selectedObject);
                    $scope.customers.content = $filter('orderBy')($scope.customers.content, 'id', 'reverse');
                } else if(selectedObject.save == "update"){
                    p.name = selectedObject.name;
                    p.phone = selectedObject.phone;
                    p.email = selectedObject.email;
                }
            });
        }            
        
        $scope.remove = function(c) {
            bootbox.confirm("Are you sure to delete "+c.name+" ?", function(result) {
                if(result) {
                    $http.delete(BASE_URL+'api/customer/remove/'+c.id).success(function(data){
                        $scope.customers.content = _.without($scope.customers.content, _.findWhere($scope.customers.content, {id:c.id}));
                    });
                }
            });
        }
        
        $scope.reloadPage = function(page){
            if(!page || page < 1) {
                page = 1;
            }
            $http.get(BASE_URL+'api/customer/fetch/'+page+'/'+$scope.itemPerPage).success(function(response){
                $scope.customers = response;
                $scope.customers.pages = [];
                for(var i=0; i<$scope.customers.totalPage; i++) $scope.customers.pages[i] = i+1;
            });
        }
        
        $scope.reloadPage();
    })
    .controller('CustomerEditController', function($scope, $modalInstance, $http, item){
        $scope.customer = angular.copy(item);
        
        $scope.cancel = function () {
            $modalInstance.dismiss('Close');
        };
        
        $scope.title = (angular.isDefined(item.id)) ? 'Edit Customer' : 'Add Customer';
        $scope.buttonText = (angular.isDefined(item.id)) ? 'Update' : 'Save';
        
        var original = item;
        $scope.isClean = function() {
            return angular.equals(original, $scope.customer);
        }
        
        $scope.save = function (c) {
            if(angular.isDefined(c.id)){
                $http.post(BASE_URL+'api/customer/update/'+c.id, c).then(function (result) {
                    var x = angular.copy(c);
                    x.save = 'update';
                    $modalInstance.close(x);
                });
            } else{
                $http.post(BASE_URL+'api/customer/save', c).then(function (result) {
                    var x = angular.copy(c);
                    x.save = 'insert';
                    x.id = result.id;                    
                    $modalInstance.close(x);
                });
            }
        };        
    })
    .controller('SeverityController', function($rootScope, $scope, $modal, $filter, $interval, $http){
        if (angular.isDefined($rootScope.Timer)) $interval.cancel($rootScope.Timer);
        if (angular.isDefined($rootScope.alarmTimer)) $interval.cancel($rootScope.alarmTimer);
        if (angular.isDefined($rootScope.nodeTimer)) $interval.cancel($rootScope.nodeTimer);
        
        $scope.severity         = {};
        $scope.severities       = {};
        $scope.severities.pages  = [];
        $scope.itemPerPage      = 10;
        
        $scope.open = function (o, s) {
            var modalInstance = $modal.open({
                templateUrl: BASE_URL+'assets/pages/severityEdit.html',
                controller: 'SeverityEditController',
                size: s,
                resolve: {
                    item: function() {
                        return o;
                    }
                }
            });
            
            modalInstance.result.then(function(selectedObject) {
                if(selectedObject.save == "insert"){
                    $scope.severities.content.push(selectedObject);
                    $scope.severities.content = $filter('orderBy')($scope.severities.content, 'id', 'reverse');
                } else if(selectedObject.save == "update"){
                    o.name = selectedObject.name;
                    o.color = selectedObject.color;
                }
            });
        }            
        
        $scope.remove = function(o) {
            bootbox.confirm("Are you sure to delete "+o.name+" ?", function(result) {
                if(result) {
                    $http.delete(BASE_URL+'api/severity/remove/'+o.id).success(function(data){
                        $scope.severities.content = _.without($scope.severities.content, _.findWhere($scope.severities.content, {id:o.id}));
                    });
                }
            });
        }
        
        $scope.reloadPage = function(page){
            if(!page || page < 1) {
                page = 1;
            }
            $http.get(BASE_URL+'api/severity/fetch/'+page+'/'+$scope.itemPerPage).success(function(response){
                $scope.severities = response;
                $scope.severities.pages = [];
                for(var i=0; i<$scope.severities.totalPage; i++) $scope.severities.pages[i] = i+1;
            });
        }
        
        $scope.reloadPage();
    })
    .controller('SeverityEditController', function($scope, $modalInstance, $http, item){
        $scope.severity = angular.copy(item);
        
        $scope.cancel = function () {
            $modalInstance.dismiss('Close');
        };
        
        $scope.title = (angular.isDefined(item.id)) ? 'Edit Severity' : 'Add Severity';
        $scope.buttonText = (angular.isDefined(item.id)) ? 'Update' : 'Save';
        
        var original = item;
        $scope.isClean = function() {
            return angular.equals(original, $scope.severity);
        }
        
        $scope.save = function (o) {
            if(angular.isDefined(o.id)){
                $http.post(BASE_URL+'api/severity/update/'+o.id, o).then(function (result) {
                    var x = angular.copy(o);
                    x.save = 'update';
                    $modalInstance.close(x);
                });
            } else{
                $http.post(BASE_URL+'api/severity/save', o).then(function (result) {
                    var x = angular.copy(o);
                    x.save = 'insert';
                    x.id = result.id;                    
                    $modalInstance.close(x);
                });
            }
        };
        
    })
    .controller('AlarmListController', function($rootScope, $scope, $modal, $filter, $interval, $http){
        if (angular.isDefined($rootScope.Timer)) $interval.cancel($rootScope.Timer);
        if (angular.isDefined($rootScope.alarmTimer)) $interval.cancel($rootScope.alarmTimer);
        if (angular.isDefined($rootScope.nodeTimer)) $interval.cancel($rootScope.nodeTimer);
        
        $scope.alarmlist            = {};
        $scope.alarmlists           = {};
        $scope.alarmlists.pages     = [];
        $scope.itemPerPage          = 10;
        
        $scope.open = function (o, s) {
            var modalInstance = $modal.open({
                templateUrl: BASE_URL+'assets/pages/alarmListEdit.html',
                controller: 'AlarmListEditController',
                size: s,
                resolve: {
                    item: function() {
                        return o;
                    }
                }
            });
            
            modalInstance.result.then(function(selectedObject) {
                $scope.reloadPage();
                /*
                if(selectedObject.save == "insert"){
                    $scope.alarmlists.content.push(selectedObject);
                    $scope.alarmlists.content = $filter('orderBy')($scope.alarmlists.content, 'id', 'reverse');
                } else if(selectedObject.save == "update"){
                    o.name = selectedObject.name;
                    o.color = selectedObject.color;
                }
                */
            });
        }
        
        $scope.remove = function(o) {
            bootbox.confirm("Are you sure to delete "+o.name+" ?", function(result) {
                if(result) {
                    $http.delete(BASE_URL+'api/alarmList/remove/'+o.id).success(function(data){
                        $scope.alarmlists.content = _.without($scope.alarmlists.content, _.findWhere($scope.alarmlists.content, {id:o.id}));
                    });
                }
            });
        }
        
        $scope.reloadPage = function(page){
            if(!page || page < 1) {
                page = 1;
            }
            $http.get(BASE_URL+'api/alarmList/fetch/'+page+'/'+$scope.itemPerPage).success(function(response){
                $scope.alarmlists = response;
                $scope.alarmlists.pages = [];
                for(var i=0; i<$scope.alarmlists.totalPage; i++) $scope.alarmlists.pages[i] = i+1;
            });
        }
        
        $scope.reloadPage();
    })
    .controller('AlarmListEditController', function($scope, $modalInstance, $http, item){
        //alert();
        $scope.severities = [];
        $scope.alarmlist = angular.copy(item);
        
        $http.get(BASE_URL+'api/severity/all').success(function(data){
            $scope.severities = data;
        });
        
        $scope.cancel = function () {
            $modalInstance.dismiss('Close');
        };
        
        $scope.title = (angular.isDefined(item.id)) ? 'Edit Alarm List' : 'Add Alarm List';
        $scope.buttonText = (angular.isDefined(item.id)) ? 'Update' : 'Save';
        
        var original = item;
        $scope.isClean = function() {
            return angular.equals(original, $scope.alarmlist);
        }
        
        $scope.save = function (o) {
            if(angular.isDefined(o.id)){
                $http.post(BASE_URL+'api/alarmList/update/'+o.id, o).then(function (result) {
                    var x = angular.copy(o);
                    x.save = 'update';
                    $modalInstance.close(x);
                });
            } else{
                $http.post(BASE_URL+'api/alarmList/save', o).then(function (result) {
                    var x = angular.copy(o);
                    x.save = 'insert';
                    x.id = result.id;                    
                    $modalInstance.close(x);
                });
            }
        };
    })
    .controller('RegionController', function($rootScope, $scope, $modal, $filter, $interval, $http){
        if (angular.isDefined($rootScope.Timer)) $interval.cancel($rootScope.Timer);
        if (angular.isDefined($rootScope.alarmTimer)) $interval.cancel($rootScope.alarmTimer);
        if (angular.isDefined($rootScope.nodeTimer)) $interval.cancel($rootScope.nodeTimer);
        
        $scope.region            = {};
        $scope.regions           = {};
        $scope.regions.pages     = [];
        $scope.itemPerPage       = 10;
        
        $scope.open = function (o, s) {
            var modalInstance = $modal.open({
                templateUrl: BASE_URL+'assets/pages/regionEdit.html',
                controller: 'RegionEditController',
                size: s,
                resolve: {
                    item: function() {
                        return o;
                    }
                }
            });
            
            modalInstance.result.then(function(selectedObject) {
                $scope.reloadPage();
            });
        }
        
        $scope.remove = function(o) {
            bootbox.confirm("Are you sure to delete "+o.name+" ?", function(result) {
                if(result) {
                    $http.delete(BASE_URL+'api/region/remove/'+o.id).success(function(data){
                        $scope.regions.content = _.without($scope.regions.content, _.findWhere($scope.regions.content, {id:o.id}));
                    });
                }
            });
        }
        
        $scope.reloadPage = function(page){
            if(!page || page < 1) {
                page = 1;
            }
            $http.get(BASE_URL+'api/region/fetch/'+page+'/'+$scope.itemPerPage).success(function(response){
                $scope.regions = response;
                $scope.regions.pages = [];
                for(var i=0; i<$scope.regions.totalPage; i++) $scope.regions.pages[i] = i+1;
            });
        }
        
        $scope.reloadPage();
    })
    .controller('RegionEditController', function($scope, $modalInstance, $http, item){
        $scope.customers = [];
        $scope.region    = angular.copy(item);
        
        $http.get(BASE_URL+'api/customer/all').success(function(data){
            $scope.customers = data;
        });
        
        $scope.cancel = function () {
            $modalInstance.dismiss('Close');
        };
        
        $scope.title = (angular.isDefined(item.id)) ? 'Edit Region' : 'Add Region';
        $scope.buttonText = (angular.isDefined(item.id)) ? 'Update' : 'Save';
        
        var original = item;
        $scope.isClean = function() {
            return angular.equals(original, $scope.region);
        }
        
        $scope.save = function (o) {
            if(angular.isDefined(o.id)){
                $http.post(BASE_URL+'api/region/update/'+o.id, o).then(function (result) {
                    var x = angular.copy(o);
                    x.save = 'update';
                    $modalInstance.close(x);
                });
            } else{
                $http.post(BASE_URL+'api/region/save', o).then(function (result) {
                    var x = angular.copy(o);
                    x.save = 'insert';
                    x.id = result.id;                    
                    $modalInstance.close(x);
                });
            }
        };
    })
    .controller('AreaController', function($rootScope, $scope, $modal, $filter, $interval, $http){
        if (angular.isDefined($rootScope.Timer)) $interval.cancel($rootScope.Timer);
        if (angular.isDefined($rootScope.alarmTimer)) $interval.cancel($rootScope.alarmTimer);
        if (angular.isDefined($rootScope.nodeTimer)) $interval.cancel($rootScope.nodeTimer);
        
        $scope.area            = {};
        $scope.areas           = {};
        $scope.areas.pages     = [];
        $scope.itemPerPage     = 10;
        
        $scope.open = function (o, s) {
            var modalInstance = $modal.open({
                templateUrl: BASE_URL+'assets/pages/areaEdit.html',
                controller: 'AreaEditController',
                size: s,
                resolve: {
                    item: function() {
                        return o;
                    }
                }
            });
            
            modalInstance.result.then(function(selectedObject) {
                $scope.reloadPage();
            });
        }
        
        $scope.remove = function(o) {
            bootbox.confirm("Are you sure to delete "+o.name+" ?", function(result) {
                if(result) {
                    $http.delete(BASE_URL+'api/area/remove/'+o.id).success(function(data){
                        $scope.areas.content = _.without($scope.areas.content, _.findWhere($scope.areas.content, {id:o.id}));
                    });
                }
            });
        }
        
        $scope.reloadPage = function(page){
            if(!page || page < 1) {
                page = 1;
            }
            $http.get(BASE_URL+'api/area/fetch/'+page+'/'+$scope.itemPerPage).success(function(response){
                $scope.areas = response;
                $scope.areas.pages = [];
                for(var i=0; i<$scope.areas.totalPage; i++) $scope.areas.pages[i] = i+1;
            });
        }
        
        $scope.reloadPage();
    })
    .controller('AreaEditController', function($scope, $modalInstance, $http, item){
        $scope.regions  = [];
        $scope.area     = angular.copy(item);
        
        $http.get(BASE_URL+'api/region/all').success(function(data){
            $scope.regions = data;
        });
        
        $scope.cancel = function () {
            $modalInstance.dismiss('Close');
        };
        
        $scope.title = (angular.isDefined(item.id)) ? 'Edit Area' : 'Add Area';
        $scope.buttonText = (angular.isDefined(item.id)) ? 'Update' : 'Save';
        
        var original = item;
        $scope.isClean = function() {
            return angular.equals(original, $scope.area);
        }
        
        $scope.save = function (o) {
            if(angular.isDefined(o.id)){
                $http.post(BASE_URL+'api/area/update/'+o.id, o).then(function (result) {
                    var x = angular.copy(o);
                    x.save = 'update';
                    $modalInstance.close(x);
                });
            } else{
                $http.post(BASE_URL+'api/area/save', o).then(function (result) {
                    var x = angular.copy(o);
                    x.save = 'insert';
                    x.id = result.id;                    
                    $modalInstance.close(x);
                });
            }
        };
    })
    .controller('SiteController', function($rootScope, $scope, $modal, $filter, $interval, $http){
        if (angular.isDefined($rootScope.Timer)) $interval.cancel($rootScope.Timer);
        if (angular.isDefined($rootScope.alarmTimer)) $interval.cancel($rootScope.alarmTimer);
        if (angular.isDefined($rootScope.nodeTimer)) $interval.cancel($rootScope.nodeTimer);
        
        $scope.site            = {};
        $scope.sites           = {};
        $scope.sites.pages     = [];
        $scope.itemPerPage       = 10;
        
        $scope.open = function (o, s) {
            var modalInstance = $modal.open({
                templateUrl: BASE_URL+'assets/pages/siteEdit.html',
                controller: 'SiteEditController',
                size: s,
                resolve: {
                    item: function() {
                        return o;
                    }
                }
            });
            
            modalInstance.result.then(function(selectedObject) {
                $scope.reloadPage();
            });
        }
        
        $scope.remove = function(o) {
            bootbox.confirm("Are you sure to delete "+o.name+" ?", function(result) {
                if(result) {
                    $http.delete(BASE_URL+'api/site/remove/'+o.id).success(function(data){
                        $scope.sites.content = _.without($scope.sites.content, _.findWhere($scope.sites.content, {id:o.id}));
                    });
                }
            });
        }
        
        $scope.reloadPage = function(page){
            if(!page || page < 1) {
                page = 1;
            }
            $http.get(BASE_URL+'api/site/fetch/'+page+'/'+$scope.itemPerPage).success(function(response){
                $scope.sites = response;
                $scope.sites.pages = [];
                for(var i=0; i<$scope.sites.totalPage; i++) $scope.sites.pages[i] = i+1;
            });
        }
        
        $scope.reloadPage();
    })
    .controller('SiteEditController', function($scope, $modalInstance, $http, item){
        $scope.areas  = [];
        $scope.customers= [];
        $scope.site     = angular.copy(item);
        
        $http.get(BASE_URL+'api/area/all').success(function(data){
            $scope.areas = data;
        });
        
        $http.get(BASE_URL+'api/customer/all').success(function(data){
            $scope.customers = data;
        });
        
        $scope.cancel = function () {
            $modalInstance.dismiss('Close');
        };
        
        $scope.title = (angular.isDefined(item.id)) ? 'Edit Site' : 'Add Site';
        $scope.buttonText = (angular.isDefined(item.id)) ? 'Update' : 'Save';
        
        var original = item;
        $scope.isClean = function() {
            return angular.equals(original, $scope.site);
        }
        
        $scope.save = function (o) {
            if(angular.isDefined(o.id)){
                $http.post(BASE_URL+'api/site/update/'+o.id, o).then(function (result) {
                    var x = angular.copy(o);
                    x.save = 'update';
                    $modalInstance.close(x);
                });
            } else{
                $http.post(BASE_URL+'api/site/save', o).then(function (result) {
                    var x = angular.copy(o);
                    x.save = 'insert';
                    x.id = result.id;                    
                    $modalInstance.close(x);
                });
            }
        };
    })
    .controller('UserController', function($rootScope, $scope, $modal, $filter, $interval, $http){
        if (angular.isDefined($rootScope.Timer)) $interval.cancel($rootScope.Timer);
        if (angular.isDefined($rootScope.alarmTimer)) $interval.cancel($rootScope.alarmTimer);
        if (angular.isDefined($rootScope.nodeTimer)) $interval.cancel($rootScope.nodeTimer);
        
        $scope.userinfo = {};
        
        $http.get(BASE_URL+'api/user/info').success(function(data){
            $scope.userinfo = data;
        });
        
        $scope.user            = {};
        $scope.users           = {};
        $scope.users.pages     = [];
        $scope.itemPerPage       = 10;
        
        $scope.open = function (o, s) {
            var modalInstance = $modal.open({
                templateUrl: BASE_URL+'assets/pages/userEdit.html',
                controller: 'UserEditController',
                size: s,
                resolve: {
                    item: function() {
                        return o;
                    }
                }
            });
            
            modalInstance.result.then(function(selectedObject) {
                $scope.reloadPage();
            });
        }
        
        $scope.remove = function(o) {
            bootbox.confirm("Are you sure to delete "+o.name+" ?", function(result) {
                if(result) {
                    $http.delete(BASE_URL+'api/user/remove/'+o.id).success(function(data){
                        $scope.users.content = _.without($scope.users.content, _.findWhere($scope.users.content, {id:o.id}));
                    });
                }
            });
        }
        
        $scope.reloadPage = function(page){
            if(!page || page < 1) {
                page = 1;
            }
            $http.get(BASE_URL+'api/user/fetch/'+page+'/'+$scope.itemPerPage).success(function(response){
                $scope.users = response;
                $scope.users.pages = [];
                for(var i=0; i<$scope.users.totalPage; i++) $scope.users.pages[i] = i+1;
            });
        }
        
        $scope.reloadPage();
    })
    .controller('UserEditController', function($scope, $modalInstance, $http, item){
        $scope.roles  = [];
        $scope.customers= [];
        $scope.user     = angular.copy(item);
        
        $http.get(BASE_URL+'api/role/all').success(function(data){
            $scope.roles = data;
        });
        
        $http.get(BASE_URL+'api/customer/all').success(function(data){
            $scope.customers = data;
        });
        
        $scope.cancel = function () {
            $modalInstance.dismiss('Close');
        };
        
        $scope.title = (angular.isDefined(item.id)) ? 'Edit User' : 'Add User';
        $scope.buttonText = (angular.isDefined(item.id)) ? 'Update' : 'Save';
        
        var original = item;
        $scope.isClean = function() {
            return angular.equals(original, $scope.user);
        }
        
        $scope.save = function (o) {
            if(angular.isDefined(o.id)){
                $http.post(BASE_URL+'api/user/update/'+o.id, o).then(function (result) {
                    var x = angular.copy(o);
                    x.save = 'update';
                    $modalInstance.close(x);
                });
            } else{
                $http.post(BASE_URL+'api/user/save', o).then(function (result) {
                    var x = angular.copy(o);
                    x.save = 'insert';
                    x.id = result.id;                    
                    $modalInstance.close(x);
                });
            }
        };
    })
    ;
    