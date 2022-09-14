<?php
/*
 * Copyright (c) 2022 Keira Dueck <sylae@calref.net>
 * Use of this source code is governed by the MIT license, which
 * can be found in the LICENSE file.
 */

abstract class HandlerBase implements HandlerInterface
{

    public function __construct(public TRSite $trs)
    {
    }

    public function errorMessage(string $msg, string $title = "Error")
    {
        echo $this->trs->twig->render("base.twig", ["errorMessage" => [$title, $msg]]);
    }

    public function unauthorizedMessage()
    {
        http_response_code(403);
        echo $this->trs->twig->render("403.twig");
    }

    /**
     * @param array $array an associative array
     * @return string
     */
    public function arrayToCSV(array $array): string
    {
        $keys = array_keys(reset($array));

        $f = fopen('php://memory', 'r+');
        fputcsv($f, $keys);
        foreach ($array as $v) {
            fputcsv($f, $v);
        }
        rewind($f);
        $csv_line = stream_get_contents($f);
        return rtrim($csv_line);
    }

    public function apiError(string $message, int $code = 500, $extraInfo = null)
    {
        $error = (object)[];
        $error->_error = $message;
        $error->_errorData = $extraInfo;

        http_response_code($code);
        echo json_encode($error, JSON_PRETTY_PRINT);
    }
}