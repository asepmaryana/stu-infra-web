angular.module('cdcApp')
    .directive('showtab', function(){
        return {
            link: function(scope, element, attrs){
                element.click(function(e){
                    e.preventDefault();
                    $(element).tab('show');
                });
            }
        };
    })
    .directive('onlyNumbers', function() {
        return function(scope, element, attrs) {
            var keyCode = [8,9,13,37,39,45,46,48,49,50,51,52,53,54,55,56,57,96,97,98,99,100,101,102,103,104,105,110,190];
            element.bind("keydown", function(event) {
                if($.inArray(event.which,keyCode) == -1) {
                    scope.$apply(function(){
                        scope.$eval(attrs.onlyNum);
                        event.preventDefault();
                    });
                    event.preventDefault();
                }
    
            });
        };
    })
    .directive('focus', function() {
        return function(scope, element) {
            element[0].focus();
        }      
    })
    .directive('typeahead', ['$compile', '$timeout', function($compile, $timeout) {
        return {
            restrict: 'A',
            transclude: true,
            scope: {
                ngModel: '=',
                typeahead: '=',
                typeaheadCallback: "="
            },
            link: function(scope, elem, attrs) {
                var template = '<div class="dropdown"><ul class="dropdown-menu" style="display:block;" ng-hide="!ngModel.length || !filitered.length || selected"><li ng-repeat="item in filitered = (typeahead | filter:{name:ngModel} | limitTo:5) track by $index" ng-click="click(item)" style="cursor:pointer" ng-class="{active:$index==active}" ng-mouseenter="mouseenter($index)"><a>{{item.name}}</a></li></ul></div>'
    
                elem.bind('blur', function() {
                    $timeout(function() {
                        scope.selected = true
                    }, 100)
                })
    
                elem.bind("keydown", function($event) {
                    if($event.keyCode == 38 && scope.active > 0) { // arrow up
                        scope.active--
                        scope.$digest()
                    } else if($event.keyCode == 40 && scope.active < scope.filitered.length - 1) { // arrow down
                        scope.active++
                        scope.$digest()
                    } else if($event.keyCode == 13) { // enter
                        scope.$apply(function() {
                            scope.click(scope.filitered[scope.active])
                        })
                    }
                })
    
                scope.click = function(item) {
                    scope.ngModel = item.name
                    scope.selected = item
                    if(scope.typeaheadCallback) {
                        scope.typeaheadCallback(item)
                    }
                    elem[0].blur()
                }
    
                scope.mouseenter = function($index) {
                    scope.active = $index
                }
    
                scope.$watch('ngModel', function(input) {
                    if(scope.selected && scope.selected.name == input) {
                        return
                    }
    
                    scope.active = 0
                    scope.selected = false
    
                    // if we have an exact match and there is only one item in the list, automatically select it
                    if(input && scope.filitered.length == 1 && scope.filitered[0].name.toLowerCase() == input.toLowerCase()) {
                        scope.click(scope.filitered[0])
                    }
                })
    
                elem.after($compile(template)(scope))
            }
        }
    }])
    ;