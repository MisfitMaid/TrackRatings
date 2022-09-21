<?php

/*
 * Copyright (c) 2022 Keira Dueck <sylae@calref.net>
 * Use of this source code is governed by the MIT license, which
 * can be found in the LICENSE file.
 */

namespace Handler;

class ListSessionsHandler extends \HandlerBase
{

    public static function registerRoutes(): array
    {
        return [
            ['GET', '/account/sessions'],
        ];
    }

    public function respond(array $vars)
    {
        $vars['breadcrumb'] = [
            '/' => 'Home',
            '/account' => 'Account management',
            '/account/sessions' => 'Active sessions',
        ];

        if (!$this->trs->user->isLogged) {
            // we're already logged in, do nothing
            $this->errorMessage("Log in to manage your account");
            return;
        }

        $vars['sessions'] = $this->trs->user->getSessions();

        $vars['locales'] = \LocaleHelper::getLocalesListWithTranslation($this->trs->user->locale);
        echo $this->trs->twig->render("listsessions.twig", $vars);
    }
}
