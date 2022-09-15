/*
 * Copyright (c) 2022 Keira Dueck <sylae@calref.net>
 * Use of this source code is governed by the MIT license, which
 * can be found in the LICENSE file.
 */

bool held = false;
void OnKeyPress(bool down, VirtualKey key)
{
	if(key == KeyToggleUI && !held)
	{
		windowVisible = !windowVisible;
	}
	if(key == KeyUpvote && !held)
	{
		startnew(VoteUp);
	}
	if(key == KeyDownvote && !held)
	{
		startnew(VoteDown);
	}
	if(key == KeyCentrist && !held)
	{
		startnew(VoteCentrist);
	}
	
	
	held = down;
}

void RenderMenu() {
	if(UI::MenuItem("\\$db4" + Icons::Circle + "\\$z Track Ratings", "", windowVisible)) {
		windowVisible = !windowVisible;
	}
}

void Render() {
	auto app = cast<CTrackMania>(GetApp());
	auto map = app.RootMap;
	
	if(!UI::IsGameUIVisible()) {
		return;
	}
	
	if(windowVisible && map !is null && map.MapInfo.MapUid != "" && app.Editor is null) {
		if(lockPosition) {
			UI::SetNextWindowPos(int(anchor.x), int(anchor.y), UI::Cond::Always);
		} else {
			UI::SetNextWindowPos(int(anchor.x), int(anchor.y), UI::Cond::FirstUseEver);
		}
		
		int windowFlags = UI::WindowFlags::NoCollapse | UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoDocking;
		if (!UI::IsOverlayShown()) {
				windowFlags |= UI::WindowFlags::NoInputs;
		}
		
		string icon;
		if (asyncInProgress) {
			icon = Icons::Download;
		} else {
			icon = Icons::StarHalfO;
		}
		UI::Begin(icon + " TrackRatings (beta)", windowFlags);
		
		if(!lockPosition) {
			anchor = UI::GetWindowPos();
		}
		
		UI::BeginGroup();
		if(displayMapName && UI::BeginTable("header", 1, UI::TableFlags::SizingFixedFit)) {
			UI::TableNextRow();
			UI::TableNextColumn();
			UI::Text(StripFormatCodes(map.MapInfo.Name));
			UI::TableNextRow();
			UI::TableNextColumn();
			UI::Text("by " + StripFormatCodes(map.MapInfo.AuthorNickName));
			UI::EndTable();
		}
		if(UI::BeginTable("table", 3, UI::TableFlags::SizingFixedFit)) {
			UI::TableNextRow();
			UI::TableNextColumn();
			if (trDat.yourVote == "--") {
				if (UI::RedButton(Icons::Minus+Icons::Minus)) { startnew(VoteDown);  }
			} else {
				if (UI::Button(Icons::Minus+Icons::Minus)) { startnew(VoteDown);  }
			}
			UI::TableNextColumn();
			if (trDat.yourVote == "O") {
				if (UI::OrangeButton("Abstain")) { startnew(VoteCentrist); }
			} else {
				if (UI::Button("Abstain")) { startnew(VoteCentrist); }
			}
			UI::TableNextColumn();
			if (trDat.yourVote == "++") {
				if (UI::GreenButton(Icons::Plus+Icons::Plus)) { startnew(VoteUp); }
			} else {
				if (UI::Button(Icons::Plus+Icons::Plus)) { startnew(VoteUp); }
			}
			
			if (displayMapCount) {
				UI::TableNextRow();
				UI::TableNextColumn();
				UI::Text(trDat.getDownCount());
				UI::TableNextColumn();
				UI::Text(trDat.getRating());
				UI::TableNextColumn();
				UI::Text(trDat.getUpCount());
			}
			if (displayMapPercent) {
				UI::TableNextRow();
				UI::TableNextColumn();
				UI::Text(trDat.getDownPct());
				UI::TableNextColumn();
				if (asyncInProgress) {
					// UI::Text(Icons::Download);
				}
				UI::TableNextColumn();
				UI::Text(trDat.getUpPct());
			}
			UI::EndTable();
		}
		
		if(apiErrorMsg.Length != 0 && UI::BeginTable("error", 1, UI::TableFlags::SizingFixedFit)) {
			UI::TableNextRow();
			UI::TableNextColumn();
			UI::Text(Icons::ExclamationTriangle + " Error");
			UI::TableNextRow();
			UI::TableNextColumn();
			UI::Text(apiErrorMsg);
			UI::EndTable();
		}
		UI::EndGroup();
		UI::End();
	}
}

void Main() {
	auto app = cast<CTrackMania>(GetApp());
	auto network = cast<CTrackManiaNetwork>(app.Network);
			
	playerInfo = TrackRatingsPlayer();
	playerInfo.uid = network.PlayerInfo.WebServicesUserId;
	playerInfo.displayName = network.PlayerInfo.Name;
	playerInfo.login = network.PlayerInfo.Login;
	playerInfo.clubTag = network.PlayerInfo.ClubTag;
	
	string currentMapUid = "";
	uint64 nextCheck = Time::Now + (refreshTime * 1000);
	
	if (phoneHomeTime < uint32(Time::Stamp)) {
		print("PHONE HOME");
		apiKey = "";
		phoneHomeTime = Time::Stamp + (86400 * 7);
	}
	
	
	if (apiKey == "") {
		startnew(AuthAppAsync);
	} else {
		print("API key already installed, not phoning home");
	}
	
	while(true) {
		auto map = app.RootMap;
		
		if(windowVisible && map !is null && map.MapInfo.MapUid != "" && app.Editor is null) {
			if(currentMapUid != map.MapInfo.MapUid) {
				currentMapUid = map.MapInfo.MapUid;
			}
			
			if (refreshTime > 0 && Time::Now > nextCheck) {
				nextCheck = Time::Now + (refreshTime * 1000);
				startnew(getMapInfo);
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
			startnew(getMapInfo);
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

TrackRating trDat;
TrackRatingsTrack currentTrack;
TrackRatingsPlayer playerInfo;

void VoteUp() {
	asyncVote("++");
}
void VoteDown() {
	asyncVote("--");
}
void VoteCentrist() {
	asyncVote("O");
}

void getMapInfo() {
	asyncInfo();
}

string apiErrorMsg = "";
bool asyncInProgress = false;
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
bool asyncInfo() {
	trace("Fetching map rating information...");
	if (apiKey.Length == 0) {
		apiErrorMsg = "No API key entered, please go to Settings";
		return false;
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
