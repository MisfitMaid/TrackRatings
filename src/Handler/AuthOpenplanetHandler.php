<?php

/*
 * Copyright (c) 2022 Keira Dueck <sylae@calref.net>
 * Use of this source code is governed by the MIT license, which
 * can be found in the LICENSE file.
 */

namespace Handler;

use GuzzleHttp\Client;

class AuthOpenplanetHandler extends \HandlerBase
{

    public static function registerRoutes(): array
    {
        return [
            ['POST', '/auth/openplanet']
        ];
    }

    public function respond(array $vars)
    {
        // get plugin token from the server
        try {
            $body = json_decode(file_get_contents('php://input'));
            if (json_last_error() != JSON_ERROR_NONE) {
                throw new \Exception();
            }
        } catch (\Throwable $e) {
            $this->apiError(json_last_error_msg(), 400, json_last_error());
            return;
        }
        $pluginToken = $body->token;
        $nadeoData = $this->requestOpenplanetVerification($pluginToken);

        if (array_key_exists("error", $nadeoData)) {
            $this->apiError("Unable to authenticate, please see Settings to do so manually.", 500, "op_error");
        }

        if (!array_key_exists("account_id", $nadeoData) || !array_key_exists("display_name", $nadeoData)) {
            $this->apiError("Unable to authenticate, please see Settings to do so manually.", 500, "op_invalid_data");
            die();
        }

        try {
            $user = \User::createFromID($this->trs, $nadeoData['account_id']);
        } catch (\InvalidArgumentException $e) {
            // no user, let's make one
            $user = \User::createNewUser(
                $this->trs,
                $nadeoData['account_id'],
                $nadeoData['display_name']
            );
        }

        $user->displayName = $nadeoData['display_name'];
        $user->clubTag = $body->clubTag;
        $user->login = $body->login;
        $user->isMember = true;
        $user->update();

        $this->trs->log("user_auth_openplanet", user: $user);
        echo json_encode(['apiKey' => $user->apiKey]);
    }

    protected function requestOpenplanetVerification(string $token): array
    {
        try {
            $client = new Client();
            $req = $client->post("https://openplanet.dev/api/auth/validate", [
                'form_params' => [
                    'secret' => $this->trs->getOpenplanetAuthToken(),
                    'token' => $token
                ],
                'headers' => [
                    'User-Agent' => 'TrackRatings <trackratings.misfitmaid.com>',
                ]
            ]);

            try {
                $body = json_decode($req->getBody(), true);
                if (json_last_error() != JSON_ERROR_NONE) {
                    throw new \Exception();
                }
                return $body;
            } catch (\Throwable $e) {
                $this->apiError(json_last_error_msg(), 400, json_last_error());
                die();
            }
        } catch (\Throwable $e) {
            $this->apiError("unable to phone home to openplanet", 500);
            die();
        }
    }


}
