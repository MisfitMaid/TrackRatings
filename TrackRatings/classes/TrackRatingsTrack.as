/*
 * Copyright (c) 2022 Keira Dueck <sylae@calref.net>
 * Use of this source code is governed by the MIT license, which
 * can be found in the LICENSE file.
 */

class TrackRatingsTrack {
	string uid;
	string mapName;
	string mapComments;
	string authorName;
	string authorLogin;
	
	
	Json::Value jsonEncode()
	{
		Json::Value json = Json::Object();
		try {
			json["uid"] = uid;
			json["mapName"] = mapName;
			json["mapNameClean"] = StripFormatCodes(mapName);
			json["mapComments"] = mapComments;
			json["authorName"] = authorName;
			json["authorNameClean"] = authorName;
			json["authorLogin"] = StripFormatCodes(authorLogin);
		} catch {
			trace("Error converting map info to JSON for map "+uid);
		}
		return json;
	}
}
