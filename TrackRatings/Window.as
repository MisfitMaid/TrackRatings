/*
 * Copyright (c) 2022 Keira Dueck <sylae@calref.net>
 * Use of this source code is governed by the MIT license, which
 * can be found in the LICENSE file.
 */

UI::Texture@ barRed;
UI::Texture@ barYellow;
UI::Texture@ barGreen;

void Render() {
	auto app = cast<CTrackMania>(GetApp());
	auto map = app.RootMap;

	if(!UI::IsGameUIVisible()) {
		return;
	}

	if(windowVisible && map !is null && map.MapInfo.MapUid != "" && app.Editor is null) {
		UI::SetNextWindowPos(int(anchor.x), int(anchor.y), UI::Cond::FirstUseEver);

		int windowFlags = UI::WindowFlags::NoCollapse | UI::WindowFlags::AlwaysAutoResize;
		if (!UI::IsOverlayShown()) {
				windowFlags |= UI::WindowFlags::NoInputs;
		}

		string icon;
		if (trApi.asyncInProgress) {
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

		if(UI::BeginTable("table", 4, UI::TableFlags::SizingFixedFit)) {

            // calc this now for bar graph formatting down below
		    int biggestVote = 0;
			for (uint i = 0; i < trDat.votecounts.Length; i++) {
			    if (trDat.votecounts[i] > biggestVote) biggestVote = trDat.votecounts[i];
			}

			auto monospace = UI::LoadFont("DroidSansMono.ttf");

			vc votechoice;
			for (uint i = 0; i < trDat.votecounts.Length; i++) {
			    UI::TableNextRow();
			    UI::TableNextColumn();
			    UI::PushFont(monospace);
			    if (trDat.yourVote == i) {
			        if (i < prettyToVote("0")) {
			            if (UI::RedButton(voteToFixedWidthPretty(i))) { votechoice.choice = i; startnew(castVote, votechoice);  }
			        } else if (i > prettyToVote("0")) {
			            if (UI::GreenButton(voteToFixedWidthPretty(i))) { votechoice.choice = i; startnew(castVote, votechoice);  }
			        } else {
			            if (UI::OrangeButton(voteToFixedWidthPretty(i))) { votechoice.choice = i; startnew(castVote, votechoice);  }
			        }
			    } else {
			        if (UI::Button(voteToFixedWidthPretty(i))) { votechoice.choice = i; startnew(castVote, votechoice);  }
			    }
			    UI::PopFont();
    		    UI::TableNextColumn();
			    UI::Text(trDat.getCountFmt(i));

			    UI::TableNextColumn();
			    UI::Text(trDat.getPercentFmt(i));

			    UI::TableNextColumn();
			    if (displayMapPercentChart && trDat.votecounts[i] > 0) {
			        float barWidth = float(trDat.votecounts[i]) / float(biggestVote) * float(mapPercentChartWidth);

                    if (i < prettyToVote("0")) {
                        UI::Image(barRed, vec2(barWidth, UI::GetTextLineHeightWithSpacing()));
                    } else if (i > prettyToVote("0")) {
                        UI::Image(barGreen, vec2(barWidth, UI::GetTextLineHeightWithSpacing()));
                    } else {
                        // this never happens lmao,
                        UI::Image(barYellow, vec2(barWidth, UI::GetTextLineHeightWithSpacing()));
                    }
                }
			}
			UI::EndTable();
		}

		if(apiErrorMsg.Length != 0 && UI::BeginTable("error", 1, UI::TableFlags::SizingFixedFit)) {
			UI::TableNextRow();
			UI::TableNextColumn();
			UI::Text(Icons::ExclamationTriangle + " Error");
			UI::TableNextRow();
			UI::TableNextColumn();
			UI::Text(trApi.errorMsg);
			UI::EndTable();
		}
		UI::EndGroup();
		UI::End();
	}
}

void loadUITextures() {
    IO::FileSource r = IO::FileSource("img/red.png");
    IO::FileSource y = IO::FileSource("img/yellow.png");
    IO::FileSource g = IO::FileSource("img/green.png");

    @barRed = UI::LoadTexture(r.Read(r.Size()));
    @barYellow = UI::LoadTexture(y.Read(y.Size()));
    @barGreen = UI::LoadTexture(g.Read(g.Size()));
}