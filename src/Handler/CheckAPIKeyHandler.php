<?php

/*
 * Copyright (c) 2022 Keira Dueck <sylae@calref.net>
 * Use of this source code is governed by the MIT license, which
 * can be found in the LICENSE file.
 */

namespace Handler;

class CheckAPIKeyHandler extends \HandlerBase
{

    public static function registerRoutes(): array
    {
        return [
            [['POST', 'GET'], '/api/keystatus']
        ];
    }

    public function respond(array $vars)
    {
        try {
            $body = json_decode(file_get_contents('php://input'));
            if (json_last_error() != JSON_ERROR_NONE) {
                throw new \Exception();
            }
        } catch (\Throwable $e) {
            $this->apiError(json_last_error_msg(), 400, json_last_error());
            return;
        }

        if (strlen($body->apiKey) > 0) {
            try {
                $user = \User::createFromAPIKey($this->trs, trim($body->apiKey));
                $this->trs->log("user_keystatus", user: $user);
            } catch (\InvalidArgumentException $e) {
                // we'll ignore invalid key and treat as guest
                $user = null;
            }
        } else {
            $user = null;
        }

        try {
            if (is_null($user)) {
                $this->apiError("Invalid key", 403);
                return;
            } else {
                echo json_encode($user);
                return;
            }
        } catch (\Throwable $e) {
            $this->apiError("Unknown error. Please try again", 500, $e->getMessage());
        }
    }
}
