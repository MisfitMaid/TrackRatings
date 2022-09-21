/*
 * Copyright (c) 2022 Keira Dueck <sylae@calref.net>
 * Use of this source code is governed by the MIT license, which
 * can be found in the LICENSE file.
 */

string apiErrorMsg = "";
bool asyncInProgress = false;
TrackRating trDat;
TrackRatingsTrack currentTrack;
TrackRatingsPlayer playerInfo;

bool keyHeldDown = false;
void OnKeyPress(bool down, VirtualKey key)
{
	if(key == KeyToggleUI && !keyHeldDown)
	{
		windowVisible = !windowVisible;
	}
	if(key == KeyUpvote && !keyHeldDown)
	{
		startnew(VoteUp);
	}
	if(key == KeyDownvote && !keyHeldDown)
	{
		startnew(VoteDown);
	}
	if(key == KeyCentrist && !keyHeldDown)
	{
		startnew(VoteCentrist);
	}

	keyHeldDown = down;
}

void RenderMenu() {
	if(UI::MenuItem("\\$db4" + Icons::StarHalfO + "\\$z Track Ratings", "", windowVisible)) {
		windowVisible = !windowVisible;
	}
}

void Main() {
    auto app = cast<CTrackMania>(GetApp());

    playerInfo = TrackRatingsPlayer();
    // wait until we have networking...
    bool isNetwork = false;
    while (!isNetwork) {
        isNetwork = playerInfo.init();
        if (!isNetwork) {
            trace("retrying player object in 1 second");
            sleep(1000);
        }
    }

	uint64 nextCheck = Time::Now + (refreshTime * 1000);
	if (apiKey == "" || phoneHomeTime < uint32(Time::Stamp)) {
		print("PHONE HOME");
		startnew(AuthAppAsync);
		phoneHomeTime = Time::Stamp + (86400 * 7);
	}

	string currentMapUid = "";
	while(true) {
		auto map = app.RootMap;
		
		if(windowVisible && map !is null && map.MapInfo.MapUid != "" && app.Editor is null) {
			if(currentMapUid != map.MapInfo.MapUid) {
				currentMapUid = map.MapInfo.MapUid;
			}
			
			if (refreshTime > 0 && Time::Now > nextCheck) {
				nextCheck = Time::Now + (refreshTime * 1000);
				startnew(asyncInfo);
			}
			
		} else if(map is null || map.MapInfo.MapUid == "") {
			currentMapUid = "";
			trDat.upCount = 0;
			trDat.downCount = 0;
			trDat.yourVote = "O";
		}
		
		if (map !is null && (currentTrack is null || currentTrack.uid != currentMapUid)) {
			currentTrack = TrackRatingsTrack();
			currentTrack.uid = map.MapInfo.MapUid;
			currentTrack.mapName = map.MapInfo.Name;
			currentTrack.mapComments = map.MapInfo.Comments;
			currentTrack.authorName = map.MapInfo.AuthorNickName;
			currentTrack.authorLogin = map.MapInfo.AuthorLogin;
			startnew(asyncInfo);
		}
		
		sleep(250);
	}
}

void AuthAppAsync()
{
	asyncInProgress = true;
	string token = Auth::GetTokenAsync();
	if (token == "") {
		apiErrorMsg = "Unable to automatically auth, see Settings->API.";
		asyncInProgress = false;
		return;			
	}
	
	Json::Value json = Json::Object();
	json["token"] = token;
	json["login"] = playerInfo.login;
	json["clubTag"] = playerInfo.clubTag;
	
	auto req = APIauth(json);
	while (!req.Finished()) {
		yield();
	}
	
	if(req.ResponseCode() == 200) {
		try {
			auto jDat = Json::Parse(req.String());
			apiKey = jDat["apiKey"];
			UI::ShowNotification("TrackRatings", "Successfully authenticated with Openplanet!");

			apiErrorMsg = "";
			asyncInProgress = false;
			return;
		} catch {
			trace(req.String());
			trace(req.ResponseCode());
			apiErrorMsg = "Can't parse server response";
			asyncInProgress = false;
			return;
		}
		
	}

	try {
		auto jDat = Json::Parse(req.String());
		apiErrorMsg = jDat["_error"];
	} catch {
		apiErrorMsg = "Unknown error, code " + req.ResponseCode();
		
	}
	trace(req.String());
	trace(req.ResponseCode());
	asyncInProgress = false;
	return;
}

void VoteUp() {
	asyncVote("++");
}
void VoteDown() {
	asyncVote("--");
}
void VoteCentrist() {
	asyncVote("O");
}

// do i have any fukken idea how to correctly get data out of the async stuff? nope

bool asyncVote(const string &in voteChoice) {
	trace("Submitting vote...");
	if (apiKey.Length == 0) {
		apiErrorMsg = "No API key entered, please go to Settings";
		return false;
	}
	
	Json::Value json = Json::Object();
	json["trackInfo"] = currentTrack.jsonEncode();
	json["playerInfo"] = playerInfo.jsonEncode();
	json["apiKey"] = apiKey;
	json["vote"] = voteChoice;
	
	asyncInProgress = true;
	auto req = APIvote(json);
	while (!req.Finished()) {
		yield();
	}
	
	if(req.ResponseCode() == 200) {
		try {
			auto jDat = Json::Parse(req.String());

			trDat.upCount = jDat["vUp"];
			trDat.downCount = jDat["vDown"];
			trDat.yourVote = jDat["myvote"];

			apiErrorMsg = "";
			asyncInProgress = false;
			UI::ShowNotification("TrackRatings", "Vote registered");
			return true;
		} catch {
			trace(req.String());
			trace(req.ResponseCode());
			apiErrorMsg = "Can't parse server response";
			asyncInProgress = false;
			return false;
		}
		
	}
	
	
	try {
		auto jDat = Json::Parse(req.String());
		apiErrorMsg = jDat["_error"];
	} catch {
		apiErrorMsg = "Unknown error, code " + req.ResponseCode();
		
	}
	trace(req.String());
	trace(req.ResponseCode());
	asyncInProgress = false;
	return false;
}

// todo: combine with asyncVote to eliminate shared code
void asyncInfo() {
	trace("Fetching map rating information...");
	if (apiKey.Length == 0) {
		apiErrorMsg = "No API key entered, please go to Settings";
		return;
	}
	
	Json::Value json = Json::Object();
	json["trackInfo"] = currentTrack.jsonEncode();
	json["playerInfo"] = playerInfo.jsonEncode();
	json["apiKey"] = apiKey;
	
	asyncInProgress = true;
	auto req = APIstate(json);
	while (!req.Finished()) {
		yield();
	}
	
	if(req.ResponseCode() == 200) {
		try {
			auto jDat = Json::Parse(req.String());

			trDat.upCount = jDat["vUp"];
			trDat.downCount = jDat["vDown"];
			try {
				trDat.yourVote = jDat["myvote"];
			} catch {
				trDat.yourVote = "O"; // bad token prolly, ignore since it doesnt matter here
			}

			apiErrorMsg = "";
			asyncInProgress = false;
			return;
		} catch {
			trace(req.String());
			trace(req.ResponseCode());
			apiErrorMsg = "Can't parse server response";
			asyncInProgress = false;
			return;
		}
		
	}
	
	try {
		auto jDat = Json::Parse(req.String());
		apiErrorMsg = jDat["_error"];
	} catch {
		apiErrorMsg = "Unknown error, code " + req.ResponseCode();
	}
	trace(req.String());
	trace(req.ResponseCode());
	asyncInProgress = false;
	return;
}
