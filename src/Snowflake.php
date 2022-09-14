<?php

/*
 * Copyright (c) 2022 Keira Dueck <sylae@calref.net>
 * Use of this source code is governed by the MIT license, which
 * can be found in the LICENSE file.
 */

class Snowflake
{
    /**
     * Time since UNIX epoch to SHART epoch. (2022-07-01 00:00 UTC)
     */
    public const EPOCH = 1656633600;

    protected static int $incrementIndex = 0;
    protected static int $incrementTime = 0;

    public int $value;
    public int $timestamp;
    public int $increment;
    public string $binary;

    /**
     * Constructor.
     */
    public function __construct(int $snowflake)
    {
        $this->value = $snowflake;

        $this->binary = \str_pad(\decbin($snowflake), 64, 0, \STR_PAD_LEFT);

        $time = $snowflake >> 6;

        $this->timestamp = $time;
        $this->increment = ($snowflake & 0x3F);

        if ($this->timestamp < static::EPOCH || $this->increment < 0 || $this->increment >= 64) {
            throw new \InvalidArgumentException('Invalid snow in snowflake');
        }
    }

    /**
     * Deconstruct a snowflake.
     */
    public static function deconstruct(int $snowflake): self
    {
        return new self($snowflake);
    }

    /**
     * Generates a new snowflake.
     */
    public static function generate(): int
    {
        $time = time();

        if ($time === static::$incrementTime) {
            static::$incrementIndex++;

            if (static::$incrementIndex >= 64) {
                sleep(1);

                $time = time();
                static::$incrementIndex = 0;
            }
        } else {
            static::$incrementIndex = 0;
            static::$incrementTime = $time;
        }

        $binary = \str_pad(\decbin($time), 58, 0, \STR_PAD_LEFT) .
            \str_pad(\decbin(static::$incrementIndex), 6, 0, \STR_PAD_LEFT);
        return \bindec($binary);
    }

    public static function format(int $snow): string
    {
        return base_convert($snow, 10, 36);
    }

    public static function parse(string $snow): int
    {
        return base_convert($snow, 36, 10);
    }
}
