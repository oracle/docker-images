app.controller('rollingRouterController', function($location, $http, $rootScope, $scope, $routeParams, $interval, $timeout)
{
	if($location.path() == '/')
	{
		if($rootScope.host && $rootScope.bearer)
		{
			var data = {};
			data.host = $rootScope.host;
			data.bearer = $rootScope.bearer;
			data.appname = $rootScope.appname;
			data.port = $rootScope.port;
			$scope.data = data;
		}
		if($rootScope.interval)
		{
			$interval.cancel($rootScope.interval);
			$rootScope.interval = null;
		}
	}

	if($location.path() == '/manage')
	{
		if($rootScope.host && $rootScope.bearer && $rootScope.appname)
		{
			$scope.data = { 'appname': $rootScope.appname };
			if($rootScope.interval)
			{
				$interval.cancel($rootScope.interval);
			} else {
				// Get the data for the 1st time, then wait the interval to trigger ..
				getData($http, $rootScope, $scope, function (err) { });
			}
			$rootScope.interval = $interval( function(){ $scope.callAtInterval($http, $rootScope); }, 10000);
		} else {
			var location = '/';
			$location.path(location);
		}
	}

	$scope.login = function(data) {
		$rootScope.host = data.host;
		$rootScope.bearer = data.bearer;
		$rootScope.appname = data.appname;
		$rootScope.port = data.port;
		var location = '/manage';
		$location.path(location);
	}

	$scope.setStickyness = function(val) {
		// Update keyvalue
		setKeyValue($http, $rootScope.host, $rootScope.bearer, 'rolling/' + $rootScope.appname + '/stickyness', val, function (err, data) {
			if(!err)
			{
				$scope.stickyness = val;
			} else {
				console.log(err);
			}
		});
	}

	$scope.setBlendpercent = function(val) {
		// Update keyvalue
		setKeyValue($http, $rootScope.host, $rootScope.bearer, 'rolling/' + $rootScope.appname + '/blendpercent', val, function (err, data) {
			if(!err)
			{
				$scope.blendpercent = val;
			} else {
				console.log(err);
			}
		});
	}

	$scope.setStable = function(val) {
		// Update keyvalue
		var value = 'apps/app-' + val + '-' + $rootScope.port + '/containers';
		setKeyValue($http, $rootScope.host, $rootScope.bearer, 'rolling/' + $rootScope.appname + '/stable/id', value, function (err, data) {
			if(!err)
			{
				$scope.stable = val;
			} else {
				console.log(err);
			}
		});
	}

	$scope.setCandidate = function(val) {
		// Update keyvalue
		var value = 'apps/app-' + val + '-' + $rootScope.port + '/containers';
		setKeyValue($http, $rootScope.host, $rootScope.bearer, 'rolling/' + $rootScope.appname + '/candidate/id', value, function (err, data) {
			if(!err)
			{
				$scope.candidate = val;
			} else {
				console.log(err);
			}
		});
	}

	$scope.promote = function() {
		$scope.promoting = 1;
		var value = 'apps/app-' + $scope.candidate + '-' + $rootScope.port + '/containers';
		setKeyValue($http, $rootScope.host, $rootScope.bearer, 'rolling/' + $rootScope.appname + '/stable/id', value, function (err, data) {
			value = 'rolling/null';
			setKeyValue($http, $rootScope.host, $rootScope.bearer, 'rolling/' + $rootScope.appname + '/candidate/id', value, function (err, data) {
				value='0';
				setKeyValue($http, $rootScope.host, $rootScope.bearer, 'rolling/' + $rootScope.appname + '/blendpercent', value, function (err, data) {
					setKeyValue($http, $rootScope.host, $rootScope.bearer, 'rolling/null', '-', function (err, data) {
						$scope.promoting = 0;
						getData($http, $rootScope, $scope, function (err) {
						});
					});
				});
			});
		});
	}

	$scope.callAtInterval = function($http, $rootScope) {
		getData($http, $rootScope, $scope, function (err) {
		});
  }

});

function getData($http, $rootScope, $scope, callback)
{
	keyValue($http, $rootScope.host, $rootScope.bearer, 'rolling/' + $rootScope.appname + '/stable/id', function (err, data) {
		if(!err)
		{
			$scope.connecterror = false;
			if(data)
			{
				formatKeyval(data, function (err, data) {
					$scope.stable = data.value;
					$rootScope.port = data.port;
					$scope.notfound = false;
				});
			} else {
				$scope.stable = '';
				$scope.notfound = true;
			}
		}  else {
			$scope.connecterror = true;
		}
	});
	keyValue($http, $rootScope.host, $rootScope.bearer, 'rolling/' + $rootScope.appname + '/candidate/id', function (err, data) {
		if(!err)
		{
			if(data)
			{
				formatKeyval(data, function (err, data) {
					$scope.candidate = data.value;
				});
			} else {
				 $scope.candidate = '';
			}
		}
	});
	keyValue($http, $rootScope.host, $rootScope.bearer, 'rolling/' + $rootScope.appname + '/blendpercent', function (err, data) {
		if(!err)
		{
			$scope.blendpercent = data;
		}
	});
	keyValue($http, $rootScope.host, $rootScope.bearer, 'rolling/' + $rootScope.appname + '/stickyness', function (err, data) {
		if(!err)
		{
			$scope.stickyness = data;
		}
	});
	getDeployments($http, $rootScope.host, $rootScope.bearer, function (err, data) {
		if(!err)
		{
			var deployment = { deployment_name : 'rolling/null', deployment_id : 'rolling/null' };
			data.push(deployment);
			$scope.deployments = data;
		}
	});
}

function keyValue(http, host, bearer, key, callback)
{
	var config = {
		headers : {
				'Content-Type': 'application/x-www-form-urlencoded;charset=utf-8;'
		}
	}
	var value = '';
	var request = $.param({
		bearer: bearer,
		host: host,
		url: '/api/kv/' + key,
		method: 'GET',
		data: ''
	});
	http.post('/REST.php', request, config)
	.success(function (data, status, headers, config) {
		  if(data[0])
			{
				value = atob(data[0].Value);
			}
			callback(null, value);
	})
	.error(function (data, status, header, config) {
			callback(status, '');
	});
}

function setKeyValue(http, host, bearer, key, value, callback)
{
	var config = {
		headers : {
				'Content-Type': 'application/x-www-form-urlencoded;charset=utf-8;'
		}
	}
	var request = $.param({
		bearer: bearer,
		host: host,
		url: '/api/kv/' + key,
		method: 'PUT',
		data: value
	});
	http.post('/REST.php', request, config)
	.success(function (data, status, headers, config) {
			callback(null, '');
	})
	.error(function (data, status, header, config) {
			callback(status, '');
	});
}

function getDeployments(http, host, bearer, callback)
{
	var config = {
		headers : {
				'Content-Type': 'application/x-www-form-urlencoded;charset=utf-8;'
		}
	}
	var value;
	var request = $.param({
		bearer: bearer,
		host: host,
		url: '/api/v2/deployments/',
		method: 'GET',
		data: ''
	});
	http.post('/REST.php', request, config)
	.success(function (data, status, headers, config) {
			callback(null, data.deployments);
	})
	.error(function (data, status, header, config) {
			callback(status, '');
	});
}

function formatKeyval(keyval, callback)
{
	var stable = keyval;
	var stable = stable.replace('apps/app-', '');
	stable = stable.replace('/containers', '');
	var port = stable.substr(stable.lastIndexOf("-")+1);
	stable = stable.replace('-' + port, '');
	var data = { 'value': stable, 'port' : port};
	callback(null, data);
}
