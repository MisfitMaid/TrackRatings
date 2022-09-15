/*
 * Copyright (c) 2022 Keira Dueck <sylae@calref.net>
 * Use of this source code is governed by the MIT license, which
 * can be found in the LICENSE file.
 */

[Setting category="Keybind Settings" name="Add ++ Rating"]
VirtualKey KeyUpvote = VirtualKey(VirtualKey::Add);

[Setting category="Keybind Settings" name="Add -- Rating"]
VirtualKey KeyDownvote = VirtualKey(VirtualKey::Subtract);

[Setting category="Keybind Settings" name="Clear Rating"]
VirtualKey KeyCentrist = VirtualKey(VirtualKey::Multiply);

[Setting category="Keybind Settings" name="Toggle UI"]
VirtualKey KeyToggleUI = VirtualKey(VirtualKey::Divide);

[Setting category="Window Settings" name="Window visible" description="To adjust the position of the window, click and drag while the Openplanet overlay is visible."]
bool windowVisible = true;

[Setting category="Window Settings" name="Hide on hidden interface"]
bool hideWithIFace = false;

[Setting category="Window Settings" name="Window position"]
vec2 anchor = vec2(0, 170);

[Setting category="Window Settings" name="Lock window position" description="Prevents the window moving when click and drag or when the game window changes size."]
bool lockPosition = false;

[Setting category="Display Settings" name="Show Map Title/Author"]
bool displayMapName = true;

[Setting category="Display Settings" name="Show Vote Counts"]
bool displayMapCount = true;

[Setting category="Display Settings" name="Show Vote Percents"]
bool displayMapPercent = true;

[Setting category="Display Settings" name="Vote refresh time" description="How often (in seconds) to poll the TrackRatings server for updated ratings. Set to 0 to only update once the map is loaded and when casting votes." min=0 max=300]
uint refreshTime = 30;

[Setting password hidden category="API Key" name="TrackRatings API" description="Get this at https://trackratings.misfitmaid.com/account. Do not show on stream as it will allow anyone to vote as you!"]
string apiKey = "";

[Setting hidden category="API Key" name="Phone Home Time" description="We'll automatically try reauthing with Openplanet after this time, just to make sure everything's still good."]
uint32 phoneHomeTime = 0;

[SettingsTab name="API Key"]
void RenderSettings()
{
	apiKey = UI::InputText("TrackRatings API key", apiKey, UI::InputTextFlags::AutoSelectAll | UI::InputTextFlags::Password);
	if (UI::Button("Get API Key")) {
		OpenBrowserURL("https://trackratings.misfitmaid.com/account");
	}
	UI::TextWrapped("In order to vote, please grab an API key by pressing the above button. Do not show this key on stream as it will allow anyone to vote as you!");
	
	UI::TextWrapped("Why do you need an API key? Without it, it would be trivial to spoof votes to the TrackRatings server, allowing bad actors to impersonate others or spam votes for their own maps. This requirement may change in the future if an Openplanet-based authentication system becomes available.");
	
	UI::Separator();

	if (UI::Button("Report a Bug / Feature Request")) {
		OpenBrowserURL("https://github.com/sylae/TrackRatings/issues/new");
	}	
	
	UI::TextWrapped("TrackRatings is a free and open-source project to bring map ratings to TrackMania without depending on server plugins or other jank. If you are interested in supporting this project or just want to say hi, please consider taking a look at the below links "+Icons::Heart);
	
	UI::Markdown(Icons::Patreon + " [https://patreon.com/MisfitMaid](https://patreon.com/MisfitMaid)");
	UI::Markdown(Icons::Paypal + " [https://paypal.me/MisfitMaid](https://paypal.me/MisfitMaid)");
	UI::Markdown(Icons::Github + " [https://github.com/sylae/trackratings](https://github.com/sylae/trackratings)");
	UI::Markdown(Icons::Discord + " [https://discord.gg/BdKpuFcYzG](https://discord.gg/BdKpuFcYzG)");
	UI::Markdown(Icons::Twitch + " [https://twitch.tv/MisfitMaid](https://twitch.tv/MisfitMaid)");
	
}

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
			
			playerInfo = TrackRatingsPlayer();
			playerInfo.uid = network.PlayerInfo.WebServicesUserId;
			playerInfo.displayName = network.PlayerInfo.Name;
			playerInfo.login = network.PlayerInfo.Login;
			playerInfo.clubTag = network.PlayerInfo.ClubTag;
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
class TrackRating {
	int upCount;
	int downCount;
	string yourVote;
	
	string getUpCount() {
		return fmt(upCount);
	}
	
	string getDownCount() {
		return fmt(downCount);
	}
	
	string getUpPct() {
		if (total() == 0) return "0%";
		return Text::Format("%.1f", float(upCount) / float(total()) * 100.f)+"%";
	}
	string getDownPct() {
		if (total() == 0) return "0%";
		return Text::Format("%.1f", float(downCount) / float(total()) * 100.f)+"%";
	}
	
	string getRating() {
		int total = upCount - downCount;
		if (total == 0) return "No votes";
		string prefix = "";
		if (total > 0) {
			prefix = "+";
		}
		return prefix+Text::Format("%d", total);
	}
	
	string fmt(uint num) {
		return Text::Format("%d", num);
	}

	uint total() {
		return upCount + downCount;
	}
}

TrackRatingsTrack currentTrack;
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

TrackRatingsPlayer playerInfo;
class TrackRatingsPlayer {
	string uid;
	string displayName;
	string login;
	string clubTag;
	
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

Net::HttpRequest@ APIvote(Json::Value json)
{
	auto ret = Net::HttpPost("https://trackratings.misfitmaid.com/api/vote", Json::Write(json), "application/json");
	return ret;
}
Net::HttpRequest@ APIstate(Json::Value json)
{
	auto ret = Net::HttpPost("https://trackratings.misfitmaid.com/api/mapinfo", Json::Write(json), "application/json");
	return ret;
}
Net::HttpRequest@ APIauth(Json::Value json)
{
	auto ret = Net::HttpPost("https://trackratings.misfitmaid.com/auth/openplanet", Json::Write(json), "application/json");
	return ret;
}


// grabbed from TMX random map plugin
namespace UI
{
    bool ColoredButton(const string &in text, float h, float s = 0.6f, float v = 0.6f)
    {
        UI::PushStyleColor(UI::Col::Button, UI::HSV(h, s, v));
        UI::PushStyleColor(UI::Col::ButtonHovered, UI::HSV(h, s + 0.1f, v + 0.1f));
        UI::PushStyleColor(UI::Col::ButtonActive, UI::HSV(h, s + 0.2f, v + 0.2f));
        bool ret = UI::Button(text);
        UI::PopStyleColor(3);
        return ret;
    }

    bool RedButton(const string &in text) { return ColoredButton(text, 0.0f); }
    bool GreenButton(const string &in text) { return ColoredButton(text, 0.33f); }
    bool OrangeButton(const string &in text) { return ColoredButton(text, 0.155f); }
    bool CyanButton(const string &in text) { return ColoredButton(text, 0.5f); }
    bool PurpleButton(const string &in text) { return ColoredButton(text, 0.8f); }
    bool RoseButton(const string &in text) { return ColoredButton(text, 0.9f); }
}
