<?php
/*
 * Copyright (c) 2022 Keira Dueck <sylae@calref.net>
 * Use of this source code is governed by the MIT license, which
 * can be found in the LICENSE file.
 */

use Doctrine\DBAL\DBALSessionHandler;
use Twig\Extra\Intl\IntlExtension;

class TRSite
{
    public \Doctrine\DBAL\Connection $db;
    public User $user;
    public bool $isTestMode;
    public \Twig\Environment $twig;
    public \League\OAuth2\Client\Provider\GenericProvider $provider;
    protected FastRoute\Dispatcher $dispatcher;

    public function __construct(protected array $config)
    {
        $this->isTestMode = $config['testMode'];

        // initialize DB
        $this->db = \Doctrine\DBAL\DriverManager::getConnection(
            ['url' => $this->config['db']],
            new \Doctrine\DBAL\Configuration()
        );

        $sessionHandler = new DBALSessionHandler($this->db);
        $sessionHandler->setUserIDType(\Doctrine\DBAL\Types\Types::STRING);
        $sessionHandler->setUserIDHandler(function () {
            return $this->user->id ?? null;
        });
        session_set_save_handler($sessionHandler, true);
        session_start([
            'cookie_lifetime' => 86400 * 7,
            'gc_maxlifetime' => 86400 * 7,
            'use_strict_mode' => true,
            'cookie_secure' => !$this->isTestMode,
            'cookie_samesite' => 'Lax',
            'lazy_write' => false,
        ]);

        // pipe any errors to DB if possible
        set_exception_handler(function (Throwable $e) {
            $this->log(
                "thrown_exception",
                remarks: json_encode(
                    [$e->getMessage(), $e->getFile(), $e->getLine(), $e->getTrace()]
                )
            );
            if ($this->isTestMode && property_exists($e, "xdebug_message")) {
                echo $e->xdebug_message;
            }
        });

        // set up oauth provider and refresh token if needed
        $this->provider = new \League\OAuth2\Client\Provider\GenericProvider($this->config['oauth']);

        try {
            if (isset($_SESSION['trTrackmaniaToken']) && $_SESSION['trTrackmaniaToken']->hasExpired()) {
                $_SESSION['trTrackmaniaToken'] = $this->provider->getAccessToken('refresh_token', [
                    'refresh_token' => $_SESSION['trTrackmaniaToken']->getRefreshToken()
                ]);
            }
        } catch (\League\OAuth2\Client\Provider\Exception\IdentityProviderException $e) {
            unset($_SESSION['trTrackmaniaToken']);
            unset($_SESSION['trLogged']);
            unset($_SESSION['trUser']);
        }

        // set HTTP endpoints
        $this->dispatcher = FastRoute\simpleDispatcher(function (\FastRoute\RouteCollector $r) {
            $classes = get_declared_classes();
            foreach ($classes as $class) {
                $ref = new ReflectionClass($class);
                if ($ref->isAbstract()) {
                    continue;
                }
                if ($ref->implementsInterface("HandlerInterface")) {
                    $routes = $class::registerRoutes();

                    foreach ($routes as $route) {
                        $r->addRoute($route[0], $route[1], $class);
                    }
                }
            }
        });

        // initialize twig stuff
        $this->twig = new \Twig\Environment(new \Twig\Loader\FilesystemLoader('tpl'), [
            'cache' => false,
        ]);
        $this->twig->addExtension(new IntlExtension());
        $this->twig->addGlobal('session', $_SESSION ?? null);
        $this->twig->addGlobal('trs', $this);

        // load user information
        $this->user = User::createFromSession($this);
    }

    public function log(
        string $type,
        int $ex1 = null,
        int $ex2 = null,
        int $ex3 = null,
        string $remarks = null,
        ?User $user = null
    ): int {
        if (PHP_SAPI == "cli") {
            $ip = inet_pton("::1");
        } else {
            $ip = inet_pton($_SERVER['REMOTE_ADDR']);
        }

        if (is_null($user)) {
            if (isset($this->user) && isset($this->user->isLogged) && $this->user->isLogged) {
                $user = $this->user->id;
            } else {
                $user = null;
            }
        }

        $qb = $this->db->createQueryBuilder()->insert("log")->values([
            'type' => '?',
            'ip' => '?',
            'idUser' => '?',
            'remarks' => '?',
            'idItemA' => '?',
            'idItemB' => '?',
            'idItemC' => '?'
        ])
            ->setParameter(0, $type, 'string')
            ->setParameter(1, $ip, 'string')
            ->setParameter(2, $user, 'string')
            ->setParameter(3, $remarks, 'string')
            ->setParameter(4, $ex1, 'integer')
            ->setParameter(5, $ex2, 'integer')
            ->setParameter(6, $ex3, 'integer');
        $qb->executeStatement();

        return $this->db->lastInsertId();
    }

    public function handleRequest()
    {
        $uri = $_SERVER['REQUEST_URI'];
        $this->log("request", remarks: $uri);
        $_SESSION['lasthit'] = time();

        if (false !== $pos = strpos($uri, '?')) {
            $uri = substr($uri, 0, $pos);
        }
        $uri = rawurldecode($uri);
        $routeInfo = $this->dispatcher->dispatch($_SERVER['REQUEST_METHOD'], $uri);
        switch ($routeInfo[0]) {
            case FastRoute\Dispatcher::NOT_FOUND:
                http_response_code(404);
                echo $this->twig->render("404.twig", ['uri' => $uri]);
                break;
            case FastRoute\Dispatcher::METHOD_NOT_ALLOWED:
                http_response_code(405);
                echo $this->twig->render("405.twig", ['allowedMethods' => $routeInfo[1]]);
                break;
            case FastRoute\Dispatcher::FOUND:
                $hname = $routeInfo[1];
                $handler = new $hname($this);
                $handler->respond($routeInfo[2]);
                break;
        }
    }

    public function getOpenplanetAuthToken()
    {
        return $this->config['openplanetAuth'];
    }

}