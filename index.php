<?php
/*
 * Copyright (c) 2022 Keira Dueck <sylae@calref.net>
 * Use of this source code is governed by the MIT license, which
 * can be found in the LICENSE file.
 */

require_once __DIR__ . '/vendor/autoload.php';
require_once __DIR__ . '/config.php';

date_default_timezone_set('UTC');

foreach (glob(__DIR__ . "/src/Handler/*.php") as $file) {
    require_once($file);
}

$trs = new TRSite($config);

$trs->handleRequest();