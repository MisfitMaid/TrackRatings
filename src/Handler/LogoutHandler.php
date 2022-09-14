<?php

/*
 * Copyright (c) 2022 Keira Dueck <sylae@calref.net>
 * Use of this source code is governed by the MIT license, which
 * can be found in the LICENSE file.
 */

namespace Handler;

class LogoutHandler extends \HandlerBase
{

    public static function registerRoutes(): array
    {
        return [
            ['GET', '/logout']
        ];
    }

    public function respond(array $vars)
    {
        if (!$this->trs->user->isLogged) {
            // we're already logged in, do nothing
            $this->errorMessage("You are already logged out. Please log in to log out.");
            return;
        }

        $this->trs->log("user_logout");
        $this->trs->user->logout();
        $redirect = $_SERVER['HTTP_REFERER'] ?? '/';
        header("Location: $redirect");
    }
}
