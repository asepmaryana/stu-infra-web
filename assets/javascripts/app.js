'use strict';
/**
 * @ngdoc overview
 * @name cdcApp
 * @description
 * # sbAdminApp
 *
 * Main module of the application.
 */
 angular
    .module('cdcApp', [
        'oc.lazyLoad',
        'ui.router',
        'ui.bootstrap',
        'angular-loading-bar',
        'ngAnimate',
        'ngResource',
        'ngTable',
        'amChartsDirective'
    ])
    .config(['$stateProvider', '$urlRouterProvider', '$ocLazyLoadProvider', function($stateProvider, $urlRouterProvider, $ocLazyLoadProvider){
        
        $ocLazyLoadProvider.config({
            debug:false,
            events:true
        });
        
        $urlRouterProvider.otherwise('/dashboard/map');
        
        $stateProvider
            .state('map', {
                url: '/dashboard/map',
                templateUrl: BASE_URL+'assets/pages/map.html',                
                controller: 'MapController'                
            })
            .state('summary', {
                url: '/dashboard/summary',
                templateUrl: BASE_URL+'assets/pages/summary.html',
                controller: 'SummaryController'                
            })
            .state('nodeview', {
                url: '/node/view/:id',
                templateUrl: BASE_URL+'assets/pages/node.html',
                controller: 'NodeController'
            })
            .state('surveillance', {
                url: '/surveillance',
                templateUrl: BASE_URL+'assets/pages/surveillance.html',
                controller: 'SurveillanceController'
            })
            .state('alarmLog', {
                url: '/alarmlog',
                templateUrl: BASE_URL+'assets/pages/alarmLog.html',
                controller: 'AlarmLogController'
            })
            .state('dataLog', {
                url: '/datalog',
                templateUrl: BASE_URL+'assets/pages/dataLog.html',
                controller: 'DataLogController'
            })
            .state('profile', {
                url: '/profile',
                templateUrl: BASE_URL+'assets/pages/profile.html',
                controller: 'ProfileController'
            })
            .state('setting', {
                url: '/setting',
                templateUrl: BASE_URL+'assets/pages/setting.html',
                controller: 'SettingController'
            })
            .state('adminCustomer', {
                url: '/admin/customer',
                templateUrl: BASE_URL+'assets/pages/customer.html',
                controller: 'CustomerController'
            })
            .state('adminSeverity', {
                url: '/admin/severity',
                templateUrl: BASE_URL+'assets/pages/severity.html',
                controller: 'SeverityController'
            })
            .state('adminList', {
                url: '/admin/alarm',
                templateUrl: BASE_URL+'assets/pages/alarmList.html',
                controller: 'AlarmListController'
            })
            .state('adminRegion', {
                url: '/admin/region',
                templateUrl: BASE_URL+'assets/pages/region.html',
                controller: 'RegionController'
            })
            .state('adminArea', {
                url: '/admin/area',
                templateUrl: BASE_URL+'assets/pages/area.html',
                controller: 'AreaController'
            })
            .state('adminSite', {
                url: '/admin/site',
                templateUrl: BASE_URL+'assets/pages/site.html',
                controller: 'SiteController'
            })
            .state('adminUser', {
                url: '/admin/user',
                templateUrl: BASE_URL+'assets/pages/user.html',
                controller: 'UserController'
            })
            .state('adminOperator', {
                url: '/admin/operator',
                templateUrl: BASE_URL+'assets/pages/operator.html',
                controller: 'OperatorController'
            })
            ;
            
    }])
    .run(function($rootScope) {
        $rootScope.Timer = null;
        $rootScope.alarmTimer = null;
        $rootScope.nodeTimer = null;
    });