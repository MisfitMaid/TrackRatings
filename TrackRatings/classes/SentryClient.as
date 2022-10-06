/*
 * Copyright (c) 2022 Keira Dueck <sylae@calref.net>
 * Use of this source code is governed by the MIT license, which
 * can be found in the LICENSE file.
 */

class SentryClient {
    string pubKey = "b093fc3ed28b4a069f32267d05bcab41";
    string host = "o4503919061565440.ingest.sentry.io";
    string projectID = "4503919064449024";

    SentryEvent@ makeEvent(const string &in level = "error") {
        auto e = SentryEvent(this, level);
        return e;
    }

}