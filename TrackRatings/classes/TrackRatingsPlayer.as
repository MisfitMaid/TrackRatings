/*
 * Copyright (c) 2022 Keira Dueck <sylae@calref.net>
 * Use of this source code is governed by the MIT license, which
 * can be found in the LICENSE file.
 */

class TrackRatingsPlayer {
	string uid;
	string displayName;
	string login;
	string clubTag;

	bool init() {
            try {
            auto app = cast<CTrackMania>(GetApp());
            auto network = cast<CTrackManiaNetwork>(app.Network);

            uid = network.PlayerInfo.WebServicesUserId;
            displayName = network.PlayerInfo.Name;
            login = network.PlayerInfo.Login;
            clubTag = network.PlayerInfo.ClubTag;
            return true;
        } catch {
            return false;
        }
	}
	
	Json::Value jsonEncode()
	{
		Json::Value json = Json::Object();
		try {
			json["uid"] = uid;
			json["displayName"] = displayName;
			json["displayNameClean"] = StripFormatCodes(displayName);
			json["login"] = login;
			json["clubTag"] = clubTag;
		} catch {
			trace("Error converting player info to JSON for player "+uid);
		}
		return json;
	}
}
