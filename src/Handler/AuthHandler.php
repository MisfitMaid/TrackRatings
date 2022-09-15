<?php

/*
 * Copyright (c) 2022 Keira Dueck <sylae@calref.net>
 * Use of this source code is governed by the MIT license, which
 * can be found in the LICENSE file.
 */

namespace Handler;

use League\OAuth2\Client\Token\AccessToken;

class AuthHandler extends \HandlerBase
{

    public static function registerRoutes(): array
    {
        return [
            ['GET', '/auth']
        ];
    }

    public function respond(array $vars)
    {
        if ($this->trs->user->isLogged) {
            // we're already logged in, do nothing
            $this->errorMessage("You are already logged in. Please log out first.");
            return;
        }

        if (!isset($_GET['code'])) {
            $authUrl = $this->trs->provider->getAuthorizationUrl(['scope' => []]);
            $_SESSION['oauth2state'] = $this->trs->provider->getState();

            if (array_key_exists('HTTP_REFERER', $_SERVER)) {
                $_SESSION['post_auth_redirect'] = $_SERVER['HTTP_REFERER'];
            }

            header('Location: ' . $authUrl);
        } elseif (empty($_GET['state']) || ($_GET['state'] !== $_SESSION['oauth2state'])) {
            unset($_SESSION['oauth2state']);
            $this->errorMessage("OAuth state failure. Please try again or seek help");
        } else {
            $token = $this->trs->provider->getAccessToken('authorization_code', [
                'code' => $_GET['code']
            ]);
            $_SESSION['trTrackmaniaToken'] = $token;

            // get user id/name from nadeo
            $nadeoData = $this->requestNadeoData($token);
            try {
                $user = \User::createFromID($this->trs, $nadeoData['accountId']);
            } catch (\InvalidArgumentException $e) {
                // no user, let's make one
                $user = \User::createNewUser(
                    $this->trs,
                    $nadeoData['accountId'],
                    $nadeoData['displayName']
                );
            }

            $user->displayName = $nadeoData['displayName'];
            $user->isMember = true;
            $user->update();

            $user->login();
            $user->isLogged = true;
            $this->trs->log("user_login", user: $user);
            $redirect = $_SESSION['post_auth_redirect'] ?? '/';
            header("Location: $redirect");
        }
    }

    /**
     * https://api.trackmania.com/doc
     */
    protected function requestNadeoData(AccessToken $token): array
    {
        return $this->trs->provider->getResourceOwner($token)->toArray();
    }

}
