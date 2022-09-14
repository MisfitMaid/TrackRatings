<?php

/*
 * Copyright (c) 2022 Keira Dueck <sylae@calref.net>
 * Use of this source code is governed by the MIT license, which
 * can be found in the LICENSE file.
 */

namespace Handler;

class MyRatingsHandler extends \HandlerBase
{

    public static function registerRoutes(): array
    {
        return [
            ['GET', '/ratings']
        ];
    }

    public function respond(array $vars)
    {
        $vars['breadcrumb'] = [
            '/' => 'Home',
            '/ratings' => 'My Ratings',
        ];

        if (!$this->trs->user->isLogged) {
            // we're already logged in, do nothing
            $this->errorMessage("Log in to view your ratings");
            return;
        }

        $vars['ratings'] = $this->trs->user->getUserRatings();
        $vars['locales'] = \LocaleHelper::getLocalesListWithTranslation($this->trs->user->locale);
        echo $this->trs->twig->render("myratings.twig", $vars);
    }
}
