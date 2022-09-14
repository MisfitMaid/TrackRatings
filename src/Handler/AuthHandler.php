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

            // get discord and sigil data
            $discordData = $this->requestDiscordData($token);
            try {
                $user = \User::createFromID($this->trs, $discordData['accountId']);
            } catch (\InvalidArgumentException $e) {
                // no user, let's make one
                $user = \User::createNewUser(
                    $this->trs,
                    $discordData['accountId'],
                    $discordData['displayName']
                );
            }

            $user->displayName = $discordData['displayName'];
            $user->isMember = true;
            $user->update();

            $user->login();
            $user->isLogged = true;
            $this->trs->log("user_login");
            $redirect = $_SESSION['post_auth_redirect'] ?? '/';
            header("Location: $redirect");
        }
    }

    /**
     * 'id' => string '297969955356540929' (length=18)
     * 'username' => string 'keira' (length=5)
     * 'avatar' => string 'e0f981cd0358e3adf5c4702dac7cdd75' (length=32)
     * 'avatar_decoration' => null
     * 'discriminator' => string '7829' (length=4)
     * 'public_flags' => int 768
     * 'flags' => int 768
     * 'banner' => string 'a_0ef8cbb956f37768e74929dcb1e1f36f' (length=34)
     * 'banner_color' => null
     * 'accent_color' => null
     * 'locale' => string 'en-GB' (length=5)
     * 'mfa_enabled' => boolean true
     * 'premium_type' => int 2
     */
    protected function requestDiscordData(AccessToken $token): array
    {
        return $this->trs->provider->getResourceOwner($token)->toArray();
    }

}
