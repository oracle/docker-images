var app = angular
  .module('rollingRouter', [
    'ngRoute',
  ])

  .config(function ($routeProvider) {
    $routeProvider
      .when('/', {
        templateUrl: '../views/setup.html',
        controller: 'rollingRouterController'
      })
      .when('/manage', {
        templateUrl: '../views/manage.html',
        controller: 'rollingRouterController'
      })
      .otherwise({
        redirectTo: '/'
      });

  });
