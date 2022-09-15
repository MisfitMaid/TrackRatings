/*
 * Copyright (c) 2022 Keira Dueck <sylae@calref.net>
 * Use of this source code is governed by the MIT license, which
 * can be found in the LICENSE file.
 */

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
		if (upCount + downCount == 0) return "No votes";
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
