<?php

/*
 * Copyright (c) 2022 Keira Dueck <sylae@calref.net>
 * Use of this source code is governed by the MIT license, which
 * can be found in the LICENSE file.
 */

namespace Handler;

class RecycleAPIHandler extends \HandlerBase
{

    public static function registerRoutes(): array
    {
        return [
            ['GET', '/recyclekey']
        ];
    }

    public function respond(array $vars)
    {
        $vars['breadcrumb'] = [
            '/' => 'Home',
            '/account' => 'Account management',
        ];

        if (!$this->trs->user->isLogged) {
            // we're already logged in, do nothing
            $this->errorMessage("Log in to manage your account");
            return;
        }

        $this->trs->user->refreshApiKey();
        $vars['friendlyMessage'] = ['Account updated', 'Your API key has been recycled.'];

        $vars['locales'] = \LocaleHelper::getLocalesListWithTranslation($this->trs->user->locale);
        echo $this->trs->twig->render("account.twig", $vars);
    }
}
