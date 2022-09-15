/*
 * Copyright (c) 2022 Keira Dueck <sylae@calref.net>
 * Use of this source code is governed by the MIT license, which
 * can be found in the LICENSE file.
 */

Net::HttpRequest@ APIvote(Json::Value json)
{
	auto ret = Net::HttpPost("https://trackratings.misfitmaid.com/api/vote", Json::Write(json), "application/json");
	return ret;
}
Net::HttpRequest@ APIstate(Json::Value json)
{
	auto ret = Net::HttpPost("https://trackratings.misfitmaid.com/api/mapinfo", Json::Write(json), "application/json");
	return ret;
}
Net::HttpRequest@ APIauth(Json::Value json)
{
	auto ret = Net::HttpPost("https://trackratings.misfitmaid.com/auth/openplanet", Json::Write(json), "application/json");
	return ret;
}
