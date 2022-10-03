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
Import::Library@ sentry;

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
    initializeSentry();

    auto eeeeeeeevent = sentry_value_new_message_event(
      /*   level */ 0,
      /*  logger */ "custom",
      /* message */ "It works!"
    );
    trace(eeeeeeeevent);
    sentry_capture_event(eeeeeeeevent);

    trApi = ServerCommunicator("https://trackratings.misfitmaid.com", apiKey);
    // trApi = ServerCommunicator("http://localhost:8000", apiKey);
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
	}
	sentry.GetFunction("sentry_close").Call();
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

void initializeSentry() {
    string sentryPath = IO::FromStorageFolder("sentry.dll");

    bool needsCopy = !IO::FileExists(sentryPath);
    // @todo: check file modification date and copy updated version as required

    if (needsCopy) {
        IO::FileSource sentryOP("sentry.dll");
        auto opref = sentryOP.Read(sentryOP.Size());
        IO::File fh(sentryPath, IO::FileMode::Write);
        fh.Write(opref);
        fh.Flush();
        fh.Close();
    }
    @sentry = Import::GetLibrary(sentryPath);

    uint64 options = sentry.GetFunction("sentry_options_new").CallPointer();
    sentry.GetFunction("sentry_options_set_dsn").Call(options, "https://b093fc3ed28b4a069f32267d05bcab41@o4503919061565440.ingest.sentry.io/4503919064449024");
    sentry.GetFunction("sentry_options_set_database_path").Call(options, IO::FromStorageFolder(".sentry-native"));
    sentry.GetFunction("sentry_options_set_release").Call(options, "trackratings-client@" + Meta::ExecutingPlugin().Version);
    sentry.GetFunction("sentry_options_set_debug").Call(options, 1);
    sentry.GetFunction("sentry_init").Call(options);
    trace("Sentry initialized.");
}

uint64 sentry_value_new_message_event(int level, const string &in logger, const string &in message) {
    return sentry.GetFunction("sentry_value_new_message_event").CallPointer(level, logger, message);
}

void sentry_capture_event(const uint64 &in event) {
    ref evRef(event);
    startnew(_sentry_capture_event, evRef);
}

void _sentry_capture_event(ref@ event) {
    auto uuid = sentry.GetFunction("sentry_capture_event").CallString(event);
    // trace(hexString(uuid));
}

string hexString(const string &in inString) {
    string[] x;
    for(int i = 0; i < inString.Length; i++) {
        x.InsertLast(Text::Format("%2x", inString[i]));
    }
    return string::Join(x, " ");
}