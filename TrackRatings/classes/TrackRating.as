/*
 * Copyright (c) 2022 Keira Dueck <sylae@calref.net>
 * Use of this source code is governed by the MIT license, which
 * can be found in the LICENSE file.
 */

class TrackRating {

	uint yourVote;
	int PB;

	int[] votecounts;

	TrackRating() {
	    wipeCounts();
	}

	void wipeCounts() {
	    yourVote = prettyToVote("0");
	    votecounts.RemoveRange(0, votecounts.Length);
	    votecounts.Resize(7);
	    for (uint i = 0; i < 7; i++) {
	        votecounts[i] = 0;
	    }
	}

    // todo: better weighting for these
	float getWeightedUps() {
	    return
	        (float(votecounts[prettyToVote("+")]) * 0.5) +
	        (float(votecounts[prettyToVote("++")]) * 1.f) +
	        (float(votecounts[prettyToVote("+++")]) * 1.5);
	}
	float getWeightedDowns() {
	    return
	        (float(votecounts[prettyToVote("-")]) * 0.5) +
	        (float(votecounts[prettyToVote("--")]) * 1.f) +
	        (float(votecounts[prettyToVote("---")]) * 1.5);
	}

	string getCountFmt(uint vote) {
	    return Text::Format("%d", votecounts[vote]);
	}

	string getPercentFmt(uint vote) {
	    if (total() == 0) return "0%";
        return Text::Format("%.1f", float(votecounts[vote]) / float(total()) * 100.f)+"%";
	}

	string getUpPct() {
		if (total() == 0) return "0%";
		return Text::Format("%.1f", getWeightedUps() / float(total()) * 100.f)+"%";
	}
	string getDownPct() {
		if (total() == 0) return "0%";
		return Text::Format("%.1f", getWeightedDowns() / float(total()) * 100.f)+"%";
	}
	
	string fmt(uint num) {
		return Text::Format("%d", num);
	}

	uint total() {
	    uint x = 0;
	    for (uint i = 0; i < votecounts.Length; i++) {
	        x += votecounts[i];
	    }
	    return x;
	}

	void ingestServerVoteData(Json::Value result) {
	    wipeCounts();
        try {
            yourVote = prettyToVote(result["myvote"]);
        } catch {
            yourVote = prettyToVote("0"); // bad token prolly, ignore since it doesnt matter here
        }

	    for (uint i = 0; i < votecounts.Length; i++) {
	        try {
	            votecounts[i] = result["voting"][voteToPretty(i)];
	        } catch {
	            votecounts[i] = 0;
	        }
	    }
	}
}
