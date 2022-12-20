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
    vc votechoice;
	if(key == KeyToggleUI && !keyHeldDown)
	{
		windowVisible = !windowVisible;
	}
	if(key == KeyUpvote && !keyHeldDown)
	{
	    votechoice.choice = prettyToVote("++");
		startnew(castVote, votechoice);
	}
	if(key == KeyDownvote && !keyHeldDown)
	{
	    votechoice.choice = prettyToVote("--");
		startnew(castVote, votechoice);
	}
	if(key == KeyCentrist && !keyHeldDown)
	{
	    votechoice.choice = prettyToVote("0");
		startnew(castVote, votechoice);
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

    string apiBase;
    if (localAPI) {
        apiBase = "http://localhost:8000";
    } else {
        apiBase = "https://trackratings.misfitmaid.com";
    }

    loadUITextures();
    trApi = ServerCommunicator(apiBase, apiKey);
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

	if (apiKey == "" || phoneHomeTime < Time::Stamp) {
		apiKey = trApi.fetchAPIKey(playerInfo);
		phoneHomeTime = Time::Stamp + (86400 * 7);
	}

	uint64 nextCheck = Time::Now + (refreshTime * 1000);
	string currentMapUid = "";
	while(true) {
	    try {
            auto map = app.RootMap;

            if(map !is null && map.MapInfo.MapUid != "" && app.Editor is null) {
                if(currentMapUid != map.MapInfo.MapUid) {
                    currentMapUid = map.MapInfo.MapUid;
                }

                if (refreshTime > 0 && Time::Now > nextCheck) {
                    nextCheck = Time::Now + (refreshTime * 1000);
                    trApi.getMapInfo(trDat, currentTrack, playerInfo);
                }

                // update our PB - code cribbed from Ultimate Medals plugin
                trDat.PB = 0;
                auto network = cast<CTrackManiaNetwork>(app.Network);
                if(network.ClientManiaAppPlayground !is null) {
                    auto userMgr = network.ClientManiaAppPlayground.UserMgr;
                    MwId userId;
                    if (userMgr.Users.Length > 0) {
                        userId = userMgr.Users[0].Id;
                    } else {
                        userId.Value = uint(-1);
                    }

                    auto scoreMgr = network.ClientManiaAppPlayground.ScoreMgr;
                    trDat.PB = scoreMgr.Map_GetRecord_v2(userId, currentTrack.uid, "PersonalBest", "", "TimeAttack", "");
                }

            } else if(map is null || map.MapInfo.MapUid == "") {
                currentMapUid = "";
                trDat.wipeCounts();
                trDat.yourVote = prettyToVote("0");
                trDat.PB = -1;
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

class vc {
    uint choice;
}

void castVote(ref@ choice) {
    trApi.vote(voteToPretty(cast<vc>(choice).choice), trDat, currentTrack, playerInfo);
}