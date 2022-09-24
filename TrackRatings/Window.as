/*
 * Copyright (c) 2022 Keira Dueck <sylae@calref.net>
 * Use of this source code is governed by the MIT license, which
 * can be found in the LICENSE file.
 */


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
