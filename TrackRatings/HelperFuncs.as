/*
 * Copyright (c) 2022 Keira Dueck <sylae@calref.net>
 * Use of this source code is governed by the MIT license, which
 * can be found in the LICENSE file.
 */

string voteToPretty(uint vote) {
    switch (vote) {
        case 0: return "---";
        case 1: return "--";
        case 2: return "-";
        case 3: return "0";
        case 4: return "+";
        case 5: return "++";
        case 6: return "+++";
        default: return "0";
    }
}

string voteToFixedWidthPretty(uint vote) {
    switch (vote) {
        case 0: return "---";
        case 1: return "- -";
        case 2: return " - ";
        case 3: return " 0 ";
        case 4: return " + ";
        case 5: return "+ +";
        case 6: return "+++";
        default: return " 0 ";
    }
}

uint prettyToVote(const string &in vote) {
    if (vote == "---") return 0;
    if (vote == "--") return 1;
    if (vote == "-") return 2;
    if (vote == "0") return 3;
    if (vote == "+") return 4;
    if (vote == "++") return 5;
    if (vote == "+++") return 6;
    return 3;
}