<?php

/*
 * Copyright (c) 2022 Keira Dueck <sylae@calref.net>
 * Use of this source code is governed by the MIT license, which
 * can be found in the LICENSE file.
 */

namespace Handler;

use GuzzleHttp\Client;

class TMXLinkHandler extends \HandlerBase
{

    public static function registerRoutes(): array
    {
        return [
            ['GET', '/maps/{map}/tmx']
        ];
    }

    public function respond(array $vars)
    {
        $client = new Client();
        $map = urlencode($vars['map']);
        $req = $client->get("https://trackmania.exchange/api/maps/get_map_info/uid/{$map}?format=application/json", [
            'headers' => [
                'User-Agent' => 'TrackRatings TMX redirector <trackratings.misfitmaid.com>',
                'Accept' => 'application/json',
            ]
        ]);

        $tID = json_decode($req->getBody())->TrackID ?? null;
        if (is_int($tID)) {
            // todo: store this so we dont have to hit TMX every time

            header("Location: https://trackmania.exchange/tracks/view/{$tID}");
        } else {
            http_response_code(404);
            die("Map ID not recognized by TMX. Try trackmania.io instead?");
        }
    }
}
