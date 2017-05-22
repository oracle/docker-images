<?php

// Mika Rinne ORACLE
if($_SERVER['REQUEST_METHOD'] == POST)
{
	$token = $_POST['bearer'];
	$host = $_POST['host'];
	$url = $_POST['url'];
	$method = $_POST['method'];
	$data = $_POST['data'];

	if(!$token || !$host || !$url || !$method)
	{
	  $token = $argv[1];
	  $host = $argv[2];
		$url = $argv[3];
		$method = $argv[4];
		$data = $argv[5];
	}

	if(!$token || !$host || !$url || !$method)
	{
	  http_response_code(400);
	  echo "Please use POST parameters: bearer host url method [data]\n";
		echo "Received:\n";
		echo $_POST['bearer'] . "\n";
		echo $_POST['host'] . "\n";
		echo $_POST['url'] . "\n";
		echo $_POST['method'] . "\n";
		echo $_POST['data'] . "\n";
	  exit;
	}

	$auth = 'Bearer ' . $token;
	$curl = curl_init();
  $headers = ['Authorization: ' . $auth ];

	if($method == 'POST')
	{
		curl_setopt_array($curl, array(
				CURLOPT_RETURNTRANSFER => 1,
				CURLOPT_URL => 'https://' . $host . $url,
				CURLOPT_HTTPHEADER => $headers,
				CURLOPT_SSL_VERIFYHOST => 0,
				CURLOPT_SSL_VERIFYPEER => 0,
				CURLOPT_FAILONERROR => 1,
				CURLOPT_POST => 1,
				CURLOPT_POSTFIELDS => $data
		));
	} else if($method == 'PUT') {
			curl_setopt_array($curl, array(
					CURLOPT_RETURNTRANSFER => 1,
					CURLOPT_URL => 'https://' . $host . $url,
					CURLOPT_HTTPHEADER => $headers,
					CURLOPT_SSL_VERIFYHOST => 0,
					CURLOPT_SSL_VERIFYPEER => 0,
					CURLOPT_FAILONERROR => 1,
					CURLOPT_CUSTOMREQUEST => 'PUT',
					CURLOPT_POSTFIELDS => $data
			));
	} else if($method == 'DELETE') {
			curl_setopt_array($curl, array(
					CURLOPT_RETURNTRANSFER => 1,
					CURLOPT_URL => 'https://' . $host . $url,
					CURLOPT_HTTPHEADER => $headers,
					CURLOPT_SSL_VERIFYHOST => 0,
					CURLOPT_SSL_VERIFYPEER => 0,
					CURLOPT_FAILONERROR => 1,
					CURLOPT_CUSTOMREQUEST => 'DELETE'
			));
	} else {
		curl_setopt_array($curl, array(
	      CURLOPT_RETURNTRANSFER => 1,
	      CURLOPT_URL => 'https://' . $host . $url,
	      CURLOPT_HTTPHEADER => $headers,
	      CURLOPT_SSL_VERIFYHOST => 0,
	      CURLOPT_SSL_VERIFYPEER => 0,
	      CURLOPT_FAILONERROR => 1
	  ));
	}

  // Send the request & save response to $resp
  $resp = curl_exec($curl);
  if($errno = curl_errno($curl)) {
      $error_message = curl_strerror($errno);
      curl_close($curl);
			http_response_code(400); // set HTTP status code BAD_REQUEST
      echo $error_message . "\n";
			echo $_POST['bearer'] . "\n";
			echo $_POST['host'] . "\n";
			echo $_POST['url'] . "\n";
			echo $_POST['method'] . "\n";
			echo $_POST['data'] . "\n";
			var_dump($headers);
  } else {
      curl_close($curl);
			//$obj = json_decode($resp, true);
      //var_dump($obj);
			echo $resp;
  }
}
