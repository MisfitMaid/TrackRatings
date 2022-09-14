<?php

/*
 * Copyright (c) 2022 Keira Dueck <sylae@calref.net>
 * Use of this source code is governed by the MIT license, which
 * can be found in the LICENSE file.
 */

namespace Handler;

class AccountHandler extends \HandlerBase
{

    public static function registerRoutes(): array
    {
        return [
            ['GET', '/account'],
            ['POST', '/account']
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
            header("Location: /auth");
            return;
        }

        if (array_key_exists("submit", $_POST)) {
            $this->trs->log("user_account_update");

            if (array_key_exists("locale", $_POST) && $_POST['locale'] != $this->trs->user->locale) {
                if (!in_array($_POST['locale'], array_keys(\LocaleHelper::getLocalesList()))) {
                    $this->errorMessage("Unknown locale. Please try again or seek help.");
                    return;
                }
                $this->trs->db->executeStatement("update users set locale = ? where idUser = ?",
                    [$_POST['locale'], $this->trs->user->id],
                    ['string', 'string']
                );
            }

            // reload the user object for our convenience
            $this->trs->user = \User::createFromSession($this->trs);
            $vars['friendlyMessage'] = ['Account updated', 'Your account has been successfully updated.'];
        }

        $vars['locales'] = \LocaleHelper::getLocalesListWithTranslation($this->trs->user->locale);
        echo $this->trs->twig->render("account.twig", $vars);
    }
}
