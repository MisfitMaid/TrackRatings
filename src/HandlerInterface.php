<?php
/*
 * Copyright (c) 2022 Keira Dueck <sylae@calref.net>
 * Use of this source code is governed by the MIT license, which
 * can be found in the LICENSE file.
 */

interface HandlerInterface
{
    public static function registerRoutes(): array;

    public function respond(array $vars);
}
