<?php

/*
 * Copyright (c) 2022 Keira Dueck <sylae@calref.net>
 * Use of this source code is governed by the MIT license, which
 * can be found in the LICENSE file.
 */

namespace Handler;

class HomepageHandler extends \HandlerBase
{

    public static function registerRoutes(): array
    {
        return [
            ['GET', '/']
        ];
    }

    public function respond(array $vars)
    {
        echo $this->trs->twig->render("home.twig", $vars);
    }
}
