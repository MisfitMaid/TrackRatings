/*
 * Copyright (c) 2022 Keira Dueck <sylae@calref.net>
 * Use of this source code is governed by the MIT license, which
 * can be found in the LICENSE file.
 */

[Setting category="Keybind Settings" name="Clear Rating"]
VirtualKey KeyCentrist = VirtualKey(VirtualKey::Multiply);

[Setting category="Keybind Settings" name="Increase Rating"]
VirtualKey KeyUpvote = VirtualKey(VirtualKey::Add);

[Setting category="Keybind Settings" name="Decrease Rating"]
VirtualKey KeyDownvote = VirtualKey(VirtualKey::Subtract);

[Setting category="Keybind Settings" name="Add +++ Rating"]
VirtualKey KeyVotePPP;

[Setting category="Keybind Settings" name="Add ++ Rating"]
VirtualKey KeyVotePP;

[Setting category="Keybind Settings" name="Add + Rating"]
VirtualKey KeyVoteP;

[Setting category="Keybind Settings" name="Add - Rating"]
VirtualKey KeyVoteM;

[Setting category="Keybind Settings" name="Add -- Rating"]
VirtualKey KeyVoteMM;

[Setting category="Keybind Settings" name="Add --- Rating"]
VirtualKey KeyVoteMMM;

[Setting hidden category="Display Settings" name="Window visible" description="To adjust the position of the window, click and drag while the Openplanet overlay is visible."]
bool windowVisible = true;

[Setting hidden category="Display Settings" name="Window position"]
vec2 anchor = vec2(0, 170);

[Setting category="Display Settings" name="Show Map Title/Author"]
bool displayMapName = true;

[Setting category="Display Settings" name="Show Vote Summary"]
bool displayVoteSummary = false;

[Setting category="Display Settings" name="Show Vote Counts"]
bool displayMapCount = true;

[Setting category="Display Settings" name="Show Vote Percents"]
bool displayMapPercent = true;

[Setting category="Display Settings" name="Show Vote Chart"]
bool displayMapPercentChart = true;

[Setting category="Display Settings" name="Vote Chart Width" min=1 max=128]
uint mapPercentChartWidth = 50;

[Setting category="Developer Settings" name="Print debug spam"]
bool debugSpam = false;

[Setting category="Developer Settings" name="Report errors to developer" description="If toggled on, this will report certain exceptions and errors to the developer via Sentry.io. The data transmitted can be viewed in the OpenPlanet Log."]
bool useSentry = false;

[Setting category="Developer Settings" name="Report to local API server" description="If toggled, after reloading the plugin will communicate with http://localhost:8000 instead of the normal TrackRatings server. Leave this off if that flew over your head."]
bool localAPI = false;

[Setting category="Display Settings" name="Vote refresh time" description="How often (in seconds) to poll the TrackRatings server for updated ratings. Set to 0 to only update once the map is loaded and when casting votes." min=0 max=300]
uint refreshTime = 30;

[Setting password hidden category="API Key" name="TrackRatings API" description="Get this at https://trackratings.misfitmaid.com/account. Do not show on stream as it will allow anyone to vote as you!"]
string apiKey = "";

[Setting hidden category="API Key" name="Phone Home Time" description="We'll automatically try reauthing with Openplanet after this time, just to make sure everything's still good."]
int64 phoneHomeTime = 0;

[SettingsTab name="API Key"]
void RenderSettings()
{
	apiKey = UI::InputText("TrackRatings API key", apiKey, UI::InputTextFlags::AutoSelectAll | UI::InputTextFlags::Password);
	UI::TextWrapped("Note: Openplanet should automatically provide the above. Only touch this value if told to.");
	if (UI::Button("Get API Key")) {
		OpenBrowserURL("https://trackratings.misfitmaid.com/account");
	}

	if (UI::Button("Report a Bug / Feature Request")) {
		OpenBrowserURL("https://github.com/MisfitMaid/TrackRatings/issues/new");
	}	
	
	UI::TextWrapped("TrackRatings is a free and open-source project to bring map ratings to TrackMania without depending on server plugins or other jank. If you are interested in supporting this project or just want to say hi, please consider taking a look at the below links "+Icons::Heart);
	
	UI::Markdown(Icons::Patreon + " [https://patreon.com/MisfitMaid](https://patreon.com/MisfitMaid)");
	UI::Markdown(Icons::Paypal + " [https://paypal.me/MisfitMaid](https://paypal.me/MisfitMaid)");
	UI::Markdown(Icons::Github + " [https://github.com/MisfitMaid/trackratings](https://github.com/MisfitMaid/trackratings)");
	UI::Markdown(Icons::Discord + " [https://discord.gg/BdKpuFcYzG](https://discord.gg/BdKpuFcYzG)");
	UI::Markdown(Icons::Twitch + " [https://twitch.tv/MisfitMaid](https://twitch.tv/MisfitMaid)");
}
