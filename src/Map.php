<?php
/*
 * Copyright (c) 2022 Keira Dueck <sylae@calref.net>
 * Use of this source code is governed by the MIT license, which
 * can be found in the LICENSE file.
 */

class Map
{
    public const VOTE_DOWN = 0;
    public const VOTE_UP = 1;
    public const VOTE_DELETE = 2;

    public string $id;
    public string $name;
    public string $authorLogin;
    public string $authorName;

    public function __construct(protected TRSite $trs)
    {
    }

    public static function createFromJSONIngest(TRSite $trs, object $json, ?User $importer): self
    {
        try {
            // todo: update from this data
            return self::createFromID($trs, $json->uid);
        } catch (\InvalidArgumentException $e) {
            return self::createNewMap(
                $trs,
                $json->uid,
                $json->mapNameClean,
                $json->authorNameClean,
                $json->authorLogin,
                $importer
            );
        }
    }

    public static function createFromID(TRSite $trs, string $idMap, bool $breakCache = false): self
    {
        static $cache = [];
        if (array_key_exists($idMap, $cache) && !$breakCache) {
            return self::createFromDBRow($trs, $cache[$idMap]);
        }
        $qb = $trs->db->createQueryBuilder();
        $qb->select("*")
            ->from("maps")
            ->where('idMap = ?')
            ->setParameter(0, $idMap);
        $res = $qb->fetchAssociative();
        if (!$res) {
            throw new \InvalidArgumentException();
        }
        $cache[$idMap] = $res;

        return self::createFromDBRow($trs, $res);
    }

    public static function createFromDBRow(TRSite $trs, array $res): self
    {
        $map = new static($trs);

        $map->id = $res['idMap'];
        $map->name = $res['name'];
        $map->authorName = $res['authorName'];
        $map->authorLogin = $res['authorLogin'];

        return $map;
    }

    public static function createNewMap(
        TRSite $trs,
        string $id,
        string $name,
        string $authorName,
        string $authorLogin,
        User $importingUser
    ): self {
        $qb = $trs->db->createQueryBuilder()->insert("maps")->values([
            'idMap' => '?',
            'name' => '?',
            'authorName' => '?',
            'authorLogin' => '?'
        ])
            ->setParameter(0, $id, 'text')
            ->setParameter(1, $name, 'text')
            ->setParameter(2, $authorName, 'text')
            ->setParameter(3, $authorLogin, 'text');
        $qb->executeStatement();

        $trs->log(
            "map_create",
            remarks: json_encode([
                    'map' => $id,
                    'importedBy' => $importingUser->id
                ]
            )
        );

        return self::createFromID($trs, $id);
    }

    public function update(): bool
    {
        return $this->trs->db->executeStatement(
            "update maps set name = ?, authorLogin = ?, authorName = ? where idMap = ?",
            [
                $this->name,
                $this->authorLogin,
                $this->authorName,
                $this->id
            ],
            [
                "string",
                "string",
                "string",
                "string"
            ]
        );
    }

    public function addVote(User $from, string $type)
    {
        $vT = match ($type) {
            "++" => self::VOTE_UP,
            "--" => self::VOTE_DOWN,
            "O" => self::VOTE_DELETE,
            default => "no",
        };

        if ($vT == "no") {
            throw new InvalidArgumentException("Unknown vote type");
        }

        if ($vT == self::VOTE_DELETE) {
            $qb = $this->trs->db->createQueryBuilder();
            $qb->delete("votes")
                ->where('idMap = ?')
                ->andWhere('idUser = ?')
                ->setParameter(0, $this->id, 'string')
                ->setParameter(1, $from->id, 'string');
            $qb->executeStatement();

            $this->trs->log(
                "vote_remove",
                remarks: json_encode([
                        'map' => $this->id,
                        'from' => $from->id
                    ]
                )
            );
        } else {
            $this->trs->db->executeStatement(
                "replace into votes (idMap, idUser, vote) values (?, ?, ?)",
                [
                    $this->id,
                    $from->id,
                    $vT
                ],
                [
                    'text',
                    'text',
                    'integer'
                ]
            );

            $this->trs->log(
                "vote_add",
                remarks: json_encode([
                        'map' => $this->id,
                        'from' => $from->id
                    ]
                )
            );
        }
    }

    public function getMapSummaryJSON(?User $from): string
    {
        $x = (object)[];

        $x->uid = $this->id;
        $x->name = $this->name;
        $x->author = $this->authorName;
        $x->authorLogin = $this->authorLogin;

        $total = $this->getVoteTotals();
        $x->vUp = $total['++'];
        $x->vDown = $total['--'];

        if (!is_null($from)) {
            $x->myvote = $this->getUserVote($from);
        }

        return json_encode($x, JSON_PRETTY_PRINT);
    }

    public function getVoteTotals(bool $breakCache = false): array
    {
        // SELECT vote, count(vote) as count FROM `votes` WHERE idMap = "ypQfnMEY70_0wqiMtPh5WQNOfg8" group by vote
        static $cache = [];
        if (array_key_exists($this->id, $cache) && !$breakCache) {
            return $cache[$this->id];
        }
        $sql = "select vote, count(vote) as count from votes where idMap = ? group by vote";
        $res = $this->trs->db->executeQuery($sql, [$this->id], ['string']);
        $x = [
            "--" => 0,
            "++" => 0,
        ];

        while ($row = $res->fetchAssociative()) {
            switch ($row['vote']) {
                case self::VOTE_UP:
                    $x['++'] = (int)$row['count'];
                    break;
                case self::VOTE_DOWN:
                    $x['--'] = (int)$row['count'];
                    break;
            }
        }

        $cache[$this->id] = $x;
        return $x;
    }

    public function getUserVote(User $from): string
    {
        $sql = "select * from votes where idMap = ? and idUser = ? group by vote ";
        $res = $this->trs->db->executeQuery($sql, [$this->id, $from->id], ['string', 'string']);

        if ($row = $res->fetchAssociative()) {
            switch ($row['vote']) {
                case self::VOTE_UP:
                    return "++";
                case self::VOTE_DOWN:
                    return "--";
            }
        }
        return "O";
    }

}