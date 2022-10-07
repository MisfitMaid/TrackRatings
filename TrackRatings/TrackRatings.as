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
bool hasCheckedKey = false;
ServerCommunicator trApi;
SentryClient sentry;

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
    sentry = SentryClient();

    loadUITextures();
    trApi = ServerCommunicator("https://trackratings.misfitmaid.com", apiKey);
    if (!hasCheckedKey) {
        if (!trApi.checkKeyStatus()) {
            apiKey = "";
        }
        hasCheckedKey = true;
    }

    auto app = cast<CTrackMania>(GetApp());

    playerInfo = TrackRatingsPlayer();
    // wait until we have networking...
    bool isNetwork = false;
    while (!isNetwork) {
        isNetwork = playerInfo.init();
        if (!isNetwork) {
            trace("retrying player object in 1 second");
            auto event = sentry.makeEvent();
            event.addMessage("Failed to create playerInfo object.");
            event.send();
            sleep(1000);
        }
    }


#if DEPENDENCY_AUTH
	if (apiKey == "" || phoneHomeTime < Time::Stamp) {
		apiKey = trApi.fetchAPIKey(playerInfo);
        trApi = ServerCommunicator("http://localhost:8000", apiKey);
		phoneHomeTime = Time::Stamp + (86400 * 7);
	}
#endif

	uint64 nextCheck = Time::Now + (refreshTime * 1000);
	string currentMapUid = "";
	while(true) {
	    try {
            auto map = app.RootMap;

            if(windowVisible && map !is null && map.MapInfo.MapUid != "" && app.Editor is null) {
                if(currentMapUid != map.MapInfo.MapUid) {
                    currentMapUid = map.MapInfo.MapUid;
                }

                if (refreshTime > 0 && Time::Now > nextCheck) {
                    nextCheck = Time::Now + (refreshTime * 1000);
                    trApi.getMapInfo(trDat, currentTrack, playerInfo);
                }

            } else if(map is null || map.MapInfo.MapUid == "") {
                currentMapUid = "";
                trDat.upCount = 0;
                trDat.downCount = 0;
                trDat.yourVote = "O";
            }

            if (map !is null && (currentTrack is null || currentTrack.uid != currentMapUid)) {
                playerInfo.init(); // refresh our player info in case name or club changed
                currentTrack = TrackRatingsTrack();
                currentTrack.uid = map.MapInfo.MapUid;
                currentTrack.mapName = map.MapInfo.Name;
                currentTrack.mapComments = map.MapInfo.Comments;
                currentTrack.authorName = map.MapInfo.AuthorNickName;
                currentTrack.authorLogin = map.MapInfo.AuthorLogin;
                trApi.getMapInfo(trDat, currentTrack, playerInfo);
            }
            sleep(250);
        } catch { // generic catch-all for anything fucky
            auto event = sentry.makeEvent();
            event.addException(getExceptionInfo(), "trackratings.main.catchloop");
            event.send();
        }
	}
}

void VoteUp() {
    trApi.vote("++", trDat, currentTrack, playerInfo);
}
void VoteDown() {
    trApi.vote("--", trDat, currentTrack, playerInfo);
}
void VoteCentrist() {
    trApi.vote("O", trDat, currentTrack, playerInfo);
}