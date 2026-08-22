package objects;

import flixel.util.FlxTimer;
import util.CardUtil;

enum Street
{
	Waiting;
	Preflop;
	Flop;
	Turn;
	River;
	Showdown;
}

enum PlayerAction
{
	Fold;
	Check;
	Call;
	Bet(target:Int);
	Raise(target:Int);
}

typedef PokerPlayer =
{
	name:String,
	isBot:Bool,
	chips:Int,
	currentBet:Int,
	folded:Bool,
	isAllIn:Bool,
	holeCards:Array<CardData>,
	isOut:Bool
}

typedef ShowdownResult =
{
	seat:Int,
	name:String,
	handText:String,
	winnings:Int,
}

enum PlayerKind
{
	Local;
	Bot;
	Opponent;
}

/**
 * Owns the poker game state and rules (players, deck, betting, streets, showdown).
 * Knows nothing about rendering or input widgets; callers drive it via `handleAction()`
 * and observe state changes through the `on*` hooks below.
 */
class Table
{
	public static inline var SMALL_BLIND = 10;
	public static inline var BIG_BLIND = 20;
	public static inline var STARTING_CHIPS = 1000;

	public var players(default, null):Array<PokerPlayer> = [];
	public var localSeat(default, null):Int = 0;
	public var community(default, null):Array<CardData> = [];
	public var pot(default, null):Int = 0;
	public var currentBet(default, null):Int = 0;
	public var dealerSeat(default, null):Int = 0;
	public var turnSeat(default, null):Int = -1;
	public var street(default, null):Street = Waiting;

	var deck:Array<CardData> = [];
	var actedThisRound:Array<Bool> = [false, false, false, false];

	public dynamic function onDeal():Void {}
	public dynamic function onCommunityCard(data:CardData, index:Int):Void {}
	public dynamic function onPotChanged():Void {}
	public dynamic function onTurnChanged(seat:Int):Void {}
	public dynamic function onPlayerActed(seat:Int, action:PlayerAction):Void {}
	public dynamic function onShowdown(results:Array<ShowdownResult>):Void {}
	public dynamic function onHandOver():Void {}

	public function new() {}

	public function addPlayer(name:String, playerKind:PlayerKind = Bot):Int
	{
		var seat = players.length;
		players.push({name: name, isBot: playerKind.match(Bot), chips: STARTING_CHIPS, currentBet: 0, folded: false, isAllIn: false, holeCards: [], isOut: false});
		if (playerKind.match(Local))
			localSeat = seat;
		dealerSeat = seat;
		return seat;
	}

	public function playersWithChips():Int
	{
		var n = 0;
		for (p in players)
			if (p.chips > 0)
				n++;
		return n;
	}

	public function startHand()
	{
		community = [];
		pot = 0;
		currentBet = 0;
		street = Preflop;
		deck = CardUtil.freshShuffledDeck();

		for (p in players)
		{
			p.currentBet = 0;
			p.isOut = p.chips <= 0;
			p.folded = p.isOut;
			p.isAllIn = false;
			p.holeCards = [];
		}

		dealerSeat = nextOccupiedSeat(dealerSeat);

		for (p in players)
			if (!p.folded)
				p.holeCards = [deck.pop(), deck.pop()];

		trace('New hand. Dealer seat $dealerSeat.');
		onDeal();

		var sbSeat = nextOccupiedSeat(dealerSeat);
		var bbSeat = nextOccupiedSeat(sbSeat);
		postBet(sbSeat, SMALL_BLIND);
		postBet(bbSeat, BIG_BLIND);
		currentBet = BIG_BLIND;

		for (i in 0...players.length)
			actedThisRound[i] = false;

		var next = nextToActSeat(bbSeat);
		if (next == -1)
			advanceStreet();
		else
			setTurn(next);
	}

	public function handleAction(seat:Int, action:PlayerAction):Bool
	{
		if (seat != turnSeat)
			return false;
		var p = players[seat];
		if (p.folded || p.isAllIn)
			return false;

		switch (action)
		{
			case Fold:
				p.folded = true;

			case Check:
				if (p.currentBet != currentBet)
					return false;

			case Call:
				var toCall = currentBet - p.currentBet;
				if (toCall <= 0)
					return false;
				postBet(seat, toCall);

			case Bet(target), Raise(target):
				var actualTarget = Std.int(Math.max(target, currentBet + BIG_BLIND));
				var toPut = actualTarget - p.currentBet;
				if (toPut <= 0)
					return false;
				toPut = Std.int(Math.min(toPut, p.chips));
				postBet(seat, toPut);
				currentBet = p.currentBet;
				for (i in 0...players.length)
					actedThisRound[i] = false;
		}

		actedThisRound[seat] = true;
		trace('${p.name} -> ${actionLabel(action)} | bet=${p.currentBet} chips=${p.chips} pot=$pot');
		onPlayerActed(seat, action);

		advanceTurn();
		return true;
	}

	public static function actionLabel(action:PlayerAction):String
	{
		return switch (action)
		{
			case Fold: "fold";
			case Check: "check";
			case Call: "call";
			case Bet(target): 'bet to $target';
			case Raise(target): 'raise to $target';
		}
	}

	function botDecideAction(seat:Int):PlayerAction
	{
		var p = players[seat];
		var toCall = currentBet - p.currentBet;
		var roll = Math.random();

		if (toCall <= 0)
		{
			if (roll < 0.65)
				return Check;

			var size = BIG_BLIND + Std.int(Math.random() * (pot > 0 ? pot : BIG_BLIND * 2));
			return Bet(currentBet + size);
		}

		if (roll < 0.15)
			return Fold;

		if (roll < 0.80)
			return Call;

		var raiseSize = BIG_BLIND + Std.int(Math.random() * BIG_BLIND * 3);
		return Raise(currentBet + raiseSize);
	}

	function postBet(seat:Int, amount:Int)
	{
		var p = players[seat];
		var actual = Std.int(Math.min(amount, p.chips));

		p.chips -= actual;
		p.currentBet += actual;
		pot += actual;

		if (p.chips <= 0)
		{
			p.isAllIn = true;
			trace('${p.name} IS ALL IN WITH ${p.currentBet}');
		}

		onPotChanged();
	}

	function nextOccupiedSeat(from:Int):Int
	{
		var seat = from;

		for (i in 0...players.length)
		{
			seat = (seat + 1) % players.length;
			if (!players[seat].isOut)
				return seat;
		}

		return from;
	}

	function nextToActSeat(from:Int):Int
	{
		var seat = from;

		for (i in 0...players.length)
		{
			seat = (seat + 1) % players.length;
			var p = players[seat];
			if (!p.isOut && !p.folded && !p.isAllIn)
				return seat;
		}

		return -1;
	}

	function allSettled():Bool
	{
		for (i in 0...players.length)
		{
			var p = players[i];
			if (p.folded || p.isAllIn)
				continue;
			if (!actedThisRound[i] || p.currentBet != currentBet)
				return false;
		}

		return true;
	}

	function setTurn(seat:Int)
	{
		turnSeat = seat;
		onTurnChanged(seat);

		if (players[seat].isBot)
			new FlxTimer().start(0.6, (_) -> handleAction(seat, botDecideAction(seat)));
	}

	function advanceTurn()
	{
		var contenders = [for (p in players) if (!p.folded) p];
		if (contenders.length <= 1)
			return awardPotToRemaining();

		if (allSettled())
			return advanceStreet();

		var next = nextToActSeat(turnSeat);
		if (next == -1)
			return advanceStreet();

		setTurn(next);
	}

	function advanceStreet()
	{
		for (i in 0...players.length)
			actedThisRound[i] = false;

		currentBet = 0;
		for (p in players)
			p.currentBet = 0;

		street = switch (street)
		{
			case Preflop: Flop;
			case Flop: Turn;
			case Turn: River;
			default: Showdown;
		}

		if (street == Showdown)
			return runShowdown();

		var toDeal = switch (street)
		{
			case Flop: 3;
			default: 1;
		}

		for (i in 0...toDeal)
		{
			var card = deck.pop();
			community.push(card);
			onCommunityCard(card, community.length - 1);
		}

		var contenders = [for (p in players) if (!p.folded) p];
		if (contenders.length <= 1)
			return awardPotToRemaining();

		var next = nextToActSeat(dealerSeat);
		if (next == -1)
			return advanceStreet();

		setTurn(next);
	}

	function awardPotToRemaining()
	{
		var winnerSeat = -1;
		for (i in 0...players.length)
			if (!players[i].folded)
			{
				winnerSeat = i;
				break;
			}

		var results:Array<ShowdownResult> = [];
		if (winnerSeat != -1)
		{
			players[winnerSeat].chips += pot;
			results.push({
				seat: winnerSeat,
				name: players[winnerSeat].name,
				handText: "Everyone else folded",
				winnings: pot,
			});
		}
		pot = 0;
		street = Showdown;
		onShowdown(results);
		onHandOver();
	}

	function runShowdown()
	{
		var contenders = [for (i in 0...players.length) if (!players[i].folded) i];
		var results = [
			for (seat in contenders)
				{seat: seat, rank: CardUtil.bestHandOf7(players[seat].holeCards.concat(community))}
		];

		results.sort((a, b) ->
		{
			if (a.rank.rank != b.rank.rank)
				return b.rank.rank - a.rank.rank;
			if (a.rank.num1 != b.rank.num1)
				return b.rank.num1 - a.rank.num1;
			return b.rank.num2 - a.rank.num2;
		});

		var best = results[0].rank;
		var winners = results.filter(r -> r.rank.rank == best.rank && r.rank.num1 == best.num1 && r.rank.num2 == best.num2);

		var share = Std.int(pot / winners.length);
		var remainder = pot - share * winners.length;

		var showdownResults:Array<ShowdownResult> = [];
		for (i in 0...winners.length)
		{
			var w = winners[i];
			var winnings = share + (i == 0 ? remainder : 0);
			players[w.seat].chips += winnings;
			showdownResults.push({
				seat: w.seat,
				name: players[w.seat].name,
				handText: CardUtil.formatCombo(w.rank),
				winnings: winnings,
			});
		}

		pot = 0;
		onShowdown(showdownResults);
		onHandOver();
	}
}
