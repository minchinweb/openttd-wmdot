/*	OperationMoney v.1, r.53a, [2011-03-31]
 *		part of WmDOT v.5
 *	Copyright © 2011 by William Minchin. For more info,
 *		please visit https://github.com/MinchinWeb/openttd-wmdot
 *
 *	Permission is granted to you to use, copy, modify, merge, publish,
 *	distribute, sublincense, and/or sell this software, and provide these
 *	rights to others, provided:
 *
 *	+ The above copyright notice and this permission notice shall be included
 *		in all copies or substantial portions of the software.
 *	+ Attribution is provided in the normal place for recognition of 3rd party
 *		contributions.
 *	+ You accept that this software is provided to you "as is", without warranty.
 */

//	Requires SuperLib v6 or better


class OpMoney {
	function GetVersion()       { return 1; }
	function GetRevision()		{ return "53a"; }
	function GetDate()          { return "2011-03-31"; }
	function GetName()          { return "Operation Money"; }

	_SleepLength = null;
	//	Controls how many ticks the AI sleeps between iterations.
	_MinBalance = null;
	//	Minimum Bank balance (in GBP - £) to have on hand

	_NextRun = null;

	Log = null;

	constructor() {
		this._SleepLength = 50;
		this._MinBalance = 100;

		this.Settings = this.Settings(this);
		this.State = this.State(this);

		Log = OpLog;
	}
};

class OpMoney.Settings {

	_main = null;

	function _set(idx, val) {
		switch (idx) {
			case "SleepLength":			this._main._SleepLength = val; break;
			case "MinBalance":			this._main._MinBalance = val; break;
			default: throw("the index '" + idx + "' does not exist");
		}
		return val;
	}

	function _get(idx) {
		switch (idx) {
			case "SleepLength":			return this._main._SleepLength; break;
			case "MinBalance":			return this._main._MinBalance; break;
			default: throw("the index '" + idx + "' does not exist");
		}
	}

	constructor(main) {
		this._main = main;
	}
}

class OpMoney.State {

	_main = null;

	function _get(idx) {
		switch (idx) {
			case "NextRun":			return this._main._NextRun; break;
			default: throw("the index '" + idx + "' does not exist");
		}
	}

	constructor(main) {
		this._main = main;
	}
}

function OpMoney::LinkUp() {
	this.Log = WmDOT.Log;
	Log.Note(this.GetName() + " linked up!",3);
}

function OpMoney::Run() {
	//	Repays the loan and keeps a small balance on hand
	this._NextRun = AIController.GetTick();
	Log.Note("OpMoney running at tick " + this._NextRun + ".",1);
	this._NextRun += this._SleepLength;

	SLMoney.MakeMaximumPayback();
	SLMoney.MakeSureToHaveAmount(this._MinBalance);
	Log.Note("Bank Balance: " + AICompany.GetBankBalance(AICompany.ResolveCompanyID(AICompany.COMPANY_SELF)) + "£, Loan: " + AICompany.GetLoanAmount() + "£, Keep Minimum Balance of " + this._MinBalance + "£.",2)
}

function OpMoney::FundsRequest(Amount) {
	//	Makes sure the requested amount is available, taking a loan if available
	Amount = Amount.tointeger();
	Log.Note("Funds Request for " + Amount + "£ received.",3);
	SLMoney.MakeSureToHaveAmount(Amount);
}

function OpMoney::GreaseMoney(Amount = 100) {
	//	Designed to keep just enough money on-hand to keep from being sold off
	SLMoney.MakeSureToHaveAmount(Amount);
}
