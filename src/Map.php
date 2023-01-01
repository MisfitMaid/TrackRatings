<?php
/*
 * Copyright (c) 2022 Keira Dueck <sylae@calref.net>
 * Use of this source code is governed by the MIT license, which
 * can be found in the LICENSE file.
 */

use GuzzleHttp\Client;

class Map
{
    public const VOTE_WORST = 3;
    public const VOTE_WORSE = 0;
    public const VOTE_BAD = 4;
    public const VOTE_CENTRIST = 2;
    public const VOTE_GOOD = 5;
    public const VOTE_BETTER = 1;
    public const VOTE_BEST = 6;

    public string $id;
    public ?int $idTMX = null;
    public string $name;
    public string $authorLogin;
    public string $authorName;

    public function __construct(protected TRSite $trs)
    {
    }

    public static function createFromJSONIngest(TRSite $trs, object $json, ?User $importer): self
    {
        if ($json->uid == "") {
            throw new InvalidArgumentException("uid cannot be empty");
        }
        if ($json->mapNameClean == "") {
            throw new InvalidArgumentException("mapName cannot be empty");
        }
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
        $map->idTMX = $res['idTMX'];
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
        ?User $importingUser = null
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
                    'map' => $id
                ]
            ),
            user: $importingUser
        );

        return self::createFromID($trs, $id);
    }

    public function addVote(User $from, string $type, ?int $PB = null)
    {
        $vT = $this->prettyToConst($type);

        if ($vT == self::VOTE_CENTRIST) {
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
                        'map' => $this->id
                    ]
                ),
                user: $from
            );
        } else {
            $this->trs->db->executeStatement(
                "replace into votes (idMap, idUser, vote, PB) values (?, ?, ?, ?)",
                [
                    $this->id,
                    $from->id,
                    $vT,
                    $PB
                ],
                [
                    'text',
                    'text',
                    'integer',
                    'integer'
                ]
            );

            $this->trs->log(
                "vote_add",
                remarks: json_encode([
                        'map' => $this->id
                    ]
                ),
                user: $from
            );
        }
    }

    public function prettyToConst(string $type): int
    {
        return match ($type) {
            "---" => self::VOTE_WORST,
            "--" => self::VOTE_WORSE,
            "-" => self::VOTE_BAD,
            default => self::VOTE_CENTRIST,
            "+" => self::VOTE_GOOD,
            "++" => self::VOTE_BETTER,
            "+++" => self::VOTE_BEST,
        };
    }

    public function getMapSummaryJSON(?User $from): string
    {
        $x = (object)[];

        $x->uid = $this->id;
        $x->name = $this->name;
        $x->author = $this->authorName;
        $x->authorLogin = $this->authorLogin;
        $x->tmxID = $this->fetchTMXid();

        $x->voting = $this->getVoteTotals();

        if (!is_null($from)) {
            $mv = $this->getUserVote($from);
            $x->myvote = $mv[0];
            $x->pb = $mv[1];
        }

        return json_encode($x, JSON_PRETTY_PRINT);
    }

    public function fetchTMXid(): ?int
    {
        if (is_int($this->idTMX)) {
            return $this->idTMX;
        } else {
            // let's try and fetch it
            try {
                $client = new Client();
                $req = $client->get(
                    "https://trackmania.exchange/api/maps/get_map_info/uid/{$this->id}?format=application/json",
                    [
                        'headers' => [
                            'User-Agent' => 'TrackRatings TMX redirector <trackratings.misfitmaid.com>',
                            'Accept' => 'application/json',
                        ]
                    ]
                );

                $tID = json_decode($req->getBody())->TrackID ?? null;
                if (is_int($tID)) {
                    $this->idTMX = $tID;
                    $this->update();
                    return $this->idTMX;
                } else {
                    return null;
                }
            } catch (\Throwable $e) {
                // that didn't go well
                return null;
            }
        }
    }

    public function update(): bool
    {
        return $this->trs->db->executeStatement(
            "update maps set name = ?, idTMX = ?, authorLogin = ?, authorName = ? where idMap = ?",
            [
                $this->name,
                $this->idTMX,
                $this->authorLogin,
                $this->authorName,
                $this->id
            ],
            [
                "string",
                "integer",
                "string",
                "string",
                "string"
            ]
        );
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
        $x = $this->blankVoteArray();

        while ($row = $res->fetchAssociative()) {
            $x[$this->constToPretty($row['vote'])] = $row['count'];
        }

        $cache[$this->id] = $x;
        return $x;
    }

    protected function blankVoteArray(): array
    {
        return [
            "---" => 0,
            "--" => 0,
            "-" => 0,
            "0" => 0,
            "+" => 0,
            "++" => 0,
            "+++" => 0,
        ];
    }

    public function constToPretty(int $type): string
    {
        return match ($type) {

            self::VOTE_WORST => "---",
            self::VOTE_WORSE => "--",
            self::VOTE_BAD => "-",
            self::VOTE_CENTRIST => "0",
            self::VOTE_GOOD => "+",
            self::VOTE_BETTER => "++",
            self::VOTE_BEST => "+++",
        };
    }

    /**
     * @return array [string (vote), int (PB)]
     */
    public function getUserVote(User $from): array
    {
        $sql = "select * from votes where idMap = ? and idUser = ? group by vote ";
        $res = $this->trs->db->executeQuery($sql, [$this->id, $from->id], ['string', 'string']);

        if ($row = $res->fetchAssociative()) {
            return [$this->constToPretty($row['vote']), $row['PB']];
        }
        return ["0", null];
    }

    public function getWeightedRating(): float
    {
        $votes = $this->getVoteTotals();
        if (array_sum($votes) == 0) {
            return 0.0;
        }

        $x = 0;
        $x += ($votes["---"] * -1.5);
        $x += ($votes["--"] * -1.0);
        $x += ($votes["-"] * -0.5);
        $x += ($votes["+"] * 0.5);
        $x += ($votes["++"] * 1.0);
        $x += ($votes["+++"] * 1.5);

        return $x / array_sum($votes);
    }

    public function getTotalVotes(): int
    {
        $votes = $this->getVoteTotals();
        return array_sum($votes);
    }

    public function getTMXScreenshot(): ?string
    {
        $base = "https://trackmania.exchange/maps/screenshot_normal/%s";

        $id = $this->fetchTMXid();
        if (is_int($id)) {
            return sprintf($base, $id);
        } else {
            return null;
        }
    }

    public function getTMXLink(): string
    {
        $base = "https://trackmania.exchange/tracks/view/%s";
        $baseNF = "/maps/%s/tmx";

        $id = $this->fetchTMXid();
        if (is_int($id)) {
            return sprintf($base, $id);
        } else {
            return sprintf($baseNF, $this->id);
        }
    }

    public function formatPB(?int $PB): string
    {
        if (is_null($PB)) {
            return "n/a";
        }

        $ci = \Carbon\CarbonInterval::milliseconds($PB)->cascade();
        $str = "";
        if ($ci->hours > 0) {
            return substr($ci->format("%H:%I:%S.%F"), 0, -3);
        } elseif ($ci->minutes > 0) {
            return substr($ci->format("%I:%S.%F"), 0, -3);
        } else {
            return substr($ci->format("%S.%F"), 0, -3);
        }
    }

}