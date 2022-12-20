/*
 * Copyright (c) 2022 Keira Dueck <sylae@calref.net>
 * Use of this source code is governed by the MIT license, which
 * can be found in the LICENSE file.
 */

class ServerCommunicator {

    string baseURL;
    string apiKey;

    string errorMsg;

    bool asyncInProgress = false;

    ServerCommunicator() {}

    ServerCommunicator(const string &in baseURL, const string &in apiKey) {
        this.baseURL = baseURL;
        this.apiKey = apiKey;
    }

    Json::Value baseAPIObject() {
    	Json::Value json = Json::Object();
    	json["apiKey"] = apiKey;
    	return json;
    }

    void getMapInfo(TrackRating &out data, TrackRatingsTrack &in map, TrackRatingsPlayer &in player) {
        Json::Value payload = this.baseAPIObject();
	    payload["playerInfo"] = player.jsonEncode();
	    payload["trackInfo"] = map.jsonEncode();

        Json::Value result;
        Net::HttpRequest req;
        if (genericAPIPost("/api/mapinfo", payload, result, req, false)) {
            if (debugSpam) {
                trace("Fetched map info");
                trace(Json::Write(result));
            }
            data.ingestServerVoteData(result);
        } else {
            auto event = sentry.makeEvent();
            string[] x;
            x.InsertLast(Json::Write(result));
            event.addMessage("Invalid map recieved: %s", x);
            event.addRequest(req);
            event.send();
            warn("Map invalid");
            if (debugSpam) {
                trace(Json::Write(result));
                trace(errorMsg);
            }
        }
    }

    void vote(const string &in vote, TrackRating &out data, TrackRatingsTrack &in map, TrackRatingsPlayer &in player) {
        Json::Value payload = this.baseAPIObject();
	    payload["playerInfo"] = player.jsonEncode();
	    payload["trackInfo"] = map.jsonEncode();
	    payload["vote"] = vote;
	    payload["pb"] = trDat.PB;

        Json::Value result;
        Net::HttpRequest req;
        if (genericAPIPost("/api/vote", payload, result, req)) {
            if (debugSpam) {
                trace("Vote successful");
                trace(Json::Write(result));
            }
			UI::ShowNotification("TrackRatings", "Vote recieved.");
            data.ingestServerVoteData(result);
        } else {
            auto event = sentry.makeEvent();
            string[] x;
            x.InsertLast(Json::Write(result));
            event.addMessage("Invalid vote data recieved: %s", x);
            event.addRequest(req);
            event.send();
            if (debugSpam) {
            warn("Vote invalid");
                trace(Json::Write(result));
                trace(errorMsg);
            }
        }
    }

    bool checkKeyStatus() {
        Json::Value payload = this.baseAPIObject();

        if(this.apiKey == "") {
            trace("null or empty api key");
            return false;
        }

        Json::Value result;
        Net::HttpRequest req;
        if (genericAPIPost("/api/keystatus", payload, result, req)) {
            return true;
        } else {
            auto event = sentry.makeEvent();
            string[] x;
            x.InsertLast(Json::Write(result));
            event.addMessage("Bad key: %s", x);
            event.addRequest(req);
            event.send();
            warn("Key invalid");
            if (debugSpam) {
                trace(Json::Write(result));
                trace(errorMsg);
            }
            return false;
        }
    }

    string fetchAPIKey(TrackRatingsPlayer &in player) {
        asyncInProgress = true;

        if (debugSpam) {
            trace("getting token from mothership");
        }

        // get a token from the mothership
        auto tokenTask = Auth::GetToken();
        while (!tokenTask.Finished()) {
            yield();
        }

        // Get the token
        string token = tokenTask.Token();
        if (debugSpam) {
            trace(token);
        }
        if (token == "") {
            auto event = sentry.makeEvent();
            event.addMessage("Auth::GetToken mothership failure");
            event.send();
            errorMsg = "Unable to automatically auth, see Settings->API.";
            asyncInProgress = false;
            return "";
        }

        Json::Value json = Json::Object();
        json["token"] = token;
        json["login"] = player.login;
        json["clubTag"] = player.clubTag;

        Json::Value result;
        Net::HttpRequest req;
        if (genericAPIPost("/auth/openplanet", json, result, req, false)) {
			UI::ShowNotification("TrackRatings", "Successfully authenticated with Openplanet!");
            return result["apiKey"];
        } else {
            auto event = sentry.makeEvent();
            event.addMessage("Auth::GetTokenAsync trackratings failure");
            event.addRequest(req);
            event.send();
            errorMsg = "Unable to automatically auth, see Settings->API.";
            if (debugSpam) {
                trace(Json::Write(result));
            }
            return "";
        }
    }

    bool genericAPIPost(string _endpoint, Json::Value payload, Json::Value &out result, Net::HttpRequest@ req, bool requireKey = true) {
        if (requireKey && apiKey.Length == 0) {
            errorMsg = "No API key entered, please go to Settings";
            return false;
        }

        asyncInProgress = true;
        @req = APIReq(baseURL + _endpoint, payload);
        while (!req.Finished()) {
            yield();
        }

        try {
            result = Json::Parse(req.String());

            if (result.GetType() == Json::Type::Null) {
                throw("not json");
            }

        } catch {
            errorMsg = "JSON parse error, see Openplanet log";

            auto event = sentry.makeEvent();
            event.addException(getExceptionInfo(), "trackratings.servercommunicator.genericAPI.badJSON");
            event.addRequest(req);
            event.send();

            if (debugSpam) {
                trace(req.String());
                trace(req.ResponseCode());
            }
            return false;
        }

        if(req.ResponseCode() == 200) {
            errorMsg = "";
            asyncInProgress = false;
            return true;
        } else {
            if (debugSpam) {
                trace(req.String());
                trace(req.ResponseCode());
            }

            errorMsg = result["_error"];
            asyncInProgress = false;
            return false;
        }
    }

    Net::HttpRequest@ APIReq(string &in url, Json::Value json)
    {
    	auto ret = Net::HttpPost(url, Json::Write(json), "application/json");
    	return ret;
    }

}