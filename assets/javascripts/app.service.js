angular.module('cdcApp')
    .factory('dataTable', ['$filter', 'ngTableParams', function($filter, ngTableParams) {

        var factoryDefinition = {
          render: function($scope, config, componentId, data) {
            
    		if(!config) config ={};
    		var config = angular.extend({}, {page:1, count:10}, config)
    		
    		$scope[componentId] = new ngTableParams(config, {
    			total: data.length, // length of data
    			getData: function($defer, params) {
    				// use build-in angular filter
    				var filteredData = params.filter() ?
    						$filter('filter')(data, params.filter()) :
    						data;
    				var orderedData = params.sorting() ?
    						$filter('orderBy')(filteredData, params.orderBy()) :
    						data;
    				params.total(orderedData.length); // set total for recalc pagination
    				$defer.resolve(orderedData.slice((params.page() - 1) * params.count(), params.page() * params.count()));
    			}
    		}); 
    		
    		
          }
        }
    	
        return factoryDefinition;
      }
    ])
    .factory('AlarmService', ['$resource', '$http', function($resource, $http){
        var service = {
            alarm: $resource(BASE_URL+'api/alarm/index/:id/:page/:size', {}, {
                queryPage: {method:'GET', isArray: false}
            }),
            get: function(param, callback){ return this.alarm.get(param, callback) },
            query: function(p, callback){ return this.alarm.queryPage({"id":id, "page":p, "size":10}, callback) },
            save: function(obj){
                if(obj.id == null){
                    return $http.post(BASE_URL+'api/alarm', obj);
                } else {
                    return $http.put(BASE_URL+'api/alarm/'+obj.id, obj);
                }
            }, 
            remove: function(obj){
                if(obj.id != null){
                    return $http.delete(BASE_URL+'api/alarm/'+obj.id);
                }
            }
        };
        
        return service;
    }]);