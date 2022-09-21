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
int64 phoneHomeTime = 0;

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
