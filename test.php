<?php
$mem = new Memcache;
$mem->connect("127.0.0.1", 11211)  or die("Could not connect");

$version = $mem->getVersion();
echo "Server's version: ".$version."<br/>\n";

$mem->set('testkey', 'Hello World', 0, 600) or die("Failed to save data at the memcached server");
echo "Store data in the cache (data will expire in 600 seconds)<br/>\n";

$get_result = $mem->get('testkey');
echo "$get_result is from memcached server.";         
?>
