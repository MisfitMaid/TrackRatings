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

            // @todo: figure out how to draw bars directly
            // ref: https://canary.discord.com/channels/276076890714800129/424967293538402334/1026764135876276244
			if (displayMapPercentChart) {
                float barWidth = UI::GetWindowContentRegionWidth() - 10.f; // arbitrarily subtract some to prevent it from becoming thicker every frame
                if (barWidth > 150) { // failsafe in case it decides to go thicccc
                    barWidth = 150.f;
                }

                if (trDat.total() == 0) {
                    UI::Image(barYellow, vec2(barWidth,10));
                } else {
                        float w = barWidth * (float(trDat.downCount) / float(trDat.total()));
                        UI::Image(barRed, vec2(w,10));
                        UI::SameLine();
                        w = barWidth * (float(trDat.upCount) / float(trDat.total()));
                        UI::Image(barGreen, vec2(w,10));
                    if (trDat.downCount > 0) {
                    }
                    if (trDat.upCount > 0) {
                    }
                }
            }
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