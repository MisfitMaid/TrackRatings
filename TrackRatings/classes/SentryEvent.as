/*
 * Copyright (c) 2022 Keira Dueck <sylae@calref.net>
 * Use of this source code is governed by the MIT license, which
 * can be found in the LICENSE file.
 */

class SentryEvent {

    Json::Value event;
    SentryClient client;

    SentryEvent() {}

    SentryEvent(SentryClient@ c, const string &in level = "error") {
        client = c;
        auto me = Meta::ExecutingPlugin();

    	event = Json::Object();
    	event["event_id"] = uuid();
    	event["level"] = level;
    	event["timestamp"] = Time::FormatStringUTC("%Y-%m-%dT%TZ"); // sentry bug: ui shows unix timestamps off by 1 hour
    	event["platform"] = "other";
    	event["release"] = me.Name + "@" + me.Version;
    	event["tags"] = Json::Object();
    	event["tags"]["openplanet.version"] = Meta::OpenplanetVersion();
    	event["tags"]["openplanet.build_date"] = Meta::OpenplanetVersionDate();
    	event["tags"]["openplanet.dev_mode"] = Meta::IsDeveloperMode();
    	event["user"] = Json::Object();
    	event["user"]["id"] = GetLocalLogin();
    	event["user"]["username"] = playerInfo.displayName;
    }

    void addRequest(Net::HttpRequest@ req) {
        event["request"] = Json::Object();
        event["request"]["method"] = stringifyMethod(req.Method);
        event["request"]["url"] = req.Url;
        event["request"]["data"] = req.Body;
    }

    void addMessage(const string &in message) { string[] x; addMessage(message, x); }
    void addMessage(const string &in message, string[] &in data) {
        trace(Json::Write(event));
        event["message"] = Json::Object();
        event["message"]["message"] = message;
        event["message"]["params"] = Json::Array();
        for (uint i = 0; i < data.Length; i++) {
            event["message"]["params"].Add(data[i]);
        }
    }

    void addException(const string &in value, const string &in module) {
        event["exception"] = Json::Object();
        event["exception"]["type"] = "Exception";
        event["exception"]["value"] = value;
        event["exception"]["module"] = module;
        event["exception"]["mechanism"] = Json::Object();
        event["exception"]["mechanism"]["type"] = "openplanet.default";
        event["exception"]["mechanism"]["synthetic"] = true;
    }

    string stringifyMethod(Net::HttpMethod method) {
        switch (method) {
            case Net::HttpMethod::Get: return "GET";
            case Net::HttpMethod::Post: return "POST";
            case Net::HttpMethod::Head: return "HEAD";
            case Net::HttpMethod::Put: return "PUT";
            case Net::HttpMethod::Delete: return "DELETE";
            case Net::HttpMethod::Patch: return "PATCH";
        }
        return ""; // SILENCE, COMPILER
    }

    string uuid() {
        return UUID::stringify(UUID::V4::generate());
    }

    Net::HttpRequest@ send()
    {
        trace("Submitting error to Sentry");
        trace(Json::Write(event));
        auto ret = Net::HttpPost(getStoreURL(), Json::Write(event), "application/json");
        return ret;
    }

    string getStoreURL() {
        return "https://" + client.host + "/api/" + client.projectID + "/store/" + getGET();
    }

    string getGET() {
        return "?sentry_version=7&sentry_key=" + client.pubKey + "&sentry_client=misfitmaid.openplanet/0.1";
    }

}