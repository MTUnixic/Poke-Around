package objects;

import flixel.FlxG;
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

private typedef OneMove = {
	var count:Int;
	var actionList:Array<PlayerAction>;
	var isStrong:Bool;
}

private enum PlayerKind
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
class TableManager
{
	public static inline var SMALL_BLIND = 10;
	public static inline var BIG_BLIND = 20;
	public static inline var STARTING_CHIPS = 1250;

	public var players(default, null):Array<PokerPlayer> = [];
	public var localSeat(default, null):Int = 0;
	public var community(default, null):Array<CardData> = [];
	public var pot(default, null):Int = 0;
	public var currentBet(default, null):Int = 0;
	public var dealerSeat(default, null):Int = 0;
	public var turnSeat(default, null):Int = -1;
	public var street(default, null):Street = Waiting;

	/**
	 * Timers used for bot thinking are created on this manager when set, so the owning state can
	 * pause/destroy them with itself. Falls back to the global manager when null.
	 */
	public var timerManager:FlxTimerManager = null;

	var deck:Array<CardData> = [];
	var actedThisRound:Array<Bool> = [false, false, false, false];

	var doubleMinRaiseArmed:Bool = false;
	var forcedFoldSeat:Int = -1;

	public var isRaiseBttnCapped = true;

	var moveCount:Array<OneMove> = []; // how many times guy[x] did something

	public dynamic function onDeal():Void {}
	public dynamic function onCommunityCard(data:CardData, index:Int):Void {}
	public dynamic function onPotChanged():Void {}
	public dynamic function onTurnChanged(seat:Int):Void {}
	public dynamic function onPlayerActed(seat:Int, action:PlayerAction):Void {}
	public dynamic function onShowdown(results:Array<ShowdownResult>):Void {}
	public dynamic function onHandOver():Void {}

	public function new() {}

	/**
		initializes a player (local or bot) and pushes it to the players' list
		@param name player identifier
		@param playerKind what kind of player is added (Bot/Local/Opponent)
		@return the current seat index of player (optional: for convenience)
	**/
	public function addPlayer(name:String, playerKind:PlayerKind = Bot):Int
	{
		var seat = players.length;

		players.push({
			name: name,
			isBot: playerKind.match(Bot),
			chips: STARTING_CHIPS,
			currentBet: 0,
			folded: false,
			isAllIn: false,
			holeCards: [],
			isOut: false
		});

		moveCount.push({
			isStrong: false,
			actionList: [],
			count: 0
		});

		if (playerKind.match(Local))
			localSeat = seat;
		else 
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

	public function peekNextCards(count:Int):Array<CardData>
	{
		var result:Array<CardData> = [];
		var i = deck.length;

		while (result.length < count && --i >= 0) // cool haxe trick you can do instead of i--; at the second line
			result.push(deck[i]);

		return result;
	}

	public function addChips(seat:Int, amount:Int)
		players[seat].chips += amount;

	public function armDoubleMinRaise()
		doubleMinRaiseArmed = true;

	public function armForcedFold(seat:Int)
		forcedFoldSeat = seat;

	public function replaceWeakestHoleCard(seat:Int):Null<{index:Int, card:CardData}>
	{
		var p = players[seat];
		if (p.holeCards.length < 2)
			return null;

		var weakestIndex = cardRank(p.holeCards[0]) <= cardRank(p.holeCards[1]) ? 0 : 1;

		var pool = p.holeCards.concat(community);
		var strongest = pool[0];
		for (c in pool)
			if (cardRank(c) > cardRank(strongest))
				strongest = c;

		var newCard:CardData = {num: strongest.num, suit: strongest.suit};
		p.holeCards[weakestIndex] = newCard;

		return {index: weakestIndex, card: newCard};
	}

	static inline function cardRank(c:CardData):Int
		return c.num == 1 ? 14 : c.num; // ace high

	public function startHand()
	{
		community = [];
		pot = 0;
		currentBet = 0;
		turnSeat = -1;
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
		final moves = moveCount[seat];

		moves.count++;

		if (seat != turnSeat)
			return false;
		var p = players[seat];
		if (p.folded || p.isAllIn)
			return false;

		if (p.holeCards.length + community.length >= 7)// fixes NOR since community cards didnt spawn yet // (community.length > 0) aint it it crashes with NOR after round end
			moves.isStrong = CardUtil.bestHandOf7(p.holeCards.concat(community)).rank >= 3; // your cards + table cards // 3 means three of a kind so a TOAK or a better is considered strong enough

		var minRaiseMultiplier = doubleMinRaiseArmed ? 2 : 1;
		doubleMinRaiseArmed = false;

		if (forcedFoldSeat == seat)
		{
			forcedFoldSeat = -1;
			action = Fold;
		}

		moves.actionList.push(action);

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
				var minTarget = currentBet + BIG_BLIND * minRaiseMultiplier;
				var actualTarget = Std.int(Math.max(target, minTarget));
				var toPut = Std.int(Math.min(actualTarget - p.currentBet, p.chips));
				if (toPut <= 0)
					return false;
				postBet(seat, toPut);

				if (p.currentBet > currentBet)
				{
					var isFullRaise = p.currentBet >= minTarget;
					currentBet = p.currentBet;
					if (isFullRaise)
						for (i in 0...players.length)
							actedThisRound[i] = false;
				}
		}

		actedThisRound[seat] = true;
		onPlayerActed(seat, action);

		advanceTurn();
		return true;
	}

	/** rate of how often the player checks from 0-1 **/
	inline function checkPassiveRate(seat:Int):Float
	{
		if (moveCount[seat].count == 0)
			return 0;
		return moveCount[seat].actionList.filter(f -> f.match(Check) || f.match(Call)).length / moveCount[seat].count; // filter checks from actionList find its length and divide it by player move count
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

	/**
	 * Maps a wanted action onto the closest action that `handleAction()` will actually accept.
	 * Bots pick actions from incomplete information, and a rejected bot action means nothing
	 * schedules the next turn, so the hand would sit there forever.
	 */
	function legalAction(seat:Int, action:PlayerAction):PlayerAction
	{
		var p = players[seat];
		var toCall = currentBet - p.currentBet;

		return switch (action)
		{
			case Fold: toCall > 0 ? Fold : Check;
			case Check: toCall > 0 ? Call : Check;
			case Call: toCall > 0 ? Call : Check;

			case Bet(target), Raise(target):
				if (p.chips <= toCall)
					toCall > 0 ? Call : Check;
				else
				{
					var actualTarget = Std.int(Math.max(target, currentBet + BIG_BLIND));
					currentBet > 0 ? Raise(actualTarget) : Bet(actualTarget);
				}
		}
	}

	/**
		Monte Carlo win probability for `seat`'s hand: deals random plausible hole cards for
		every live opponent plus the remaining community cards over many trials, and returns
		the fraction of the pot `seat` would win on average (ties split). Works unchanged from
		preflop (samples all 5 community cards) through the river (samples none).

		Replaces a flawed hand-category-only score that rated any single pair as ~11% strength
		(rank 1 / 9) and unmade draws as 0%, which made the bot fold strong made hands and
		well-priced draws far too often, and check/call instead of betting them for value.
		@returns range between 0.0 and 1.0
	**/
	function handEquity(seat:Int, trials:Int = 200):Float
	{
		var me = players[seat];
		var opponents = [for (i in 0...players.length) if (i != seat && !players[i].isOut && !players[i].folded) i];
		if (opponents.length == 0)
			return 1;

		inline function cardKey(c:CardData):Int
			return c.suit * 13 + c.num;

		var known:Map<Int, Bool> = new Map();
		for (c in me.holeCards)
			known.set(cardKey(c), true);
		for (c in community)
			known.set(cardKey(c), true);

		var unseen:Array<CardData> = [];
		for (suit in 0...4)
			for (num in 1...14)
			{
				var c:CardData = {suit: suit, num: num};
				if (!known.exists(cardKey(c)))
					unseen.push(c);
			}

		var boardNeeded = 5 - community.length;
		var cardsNeeded = opponents.length * 2 + boardNeeded;
		if (cardsNeeded > unseen.length)
			return 0.5;

		var equitySum = 0.0;

		for (t in 0...trials)
		{
			// partial Fisher-Yates: only the prefix we're about to deal needs to be randomized
			for (i in 0...cardsNeeded)
			{
				var j = i + FlxG.random.int(0, unseen.length - i - 1);
				var tmp = unseen[i];
				unseen[i] = unseen[j];
				unseen[j] = tmp;
			}

			var idx = 0;
			var board = community.copy();
			for (i in 0...boardNeeded)
				board.push(unseen[idx++]);

			var myRank = CardUtil.bestHandOf7(me.holeCards.concat(board));

			var tiedCount = 1;
			var beaten = false;
			for (o in opponents)
			{
				var oppHole = [unseen[idx++], unseen[idx++]];
				var cmp = compareHandRank(myRank, CardUtil.bestHandOf7(oppHole.concat(board)));
				if (cmp < 0)
					beaten = true;
				else if (cmp == 0)
					tiedCount++;
			}

			if (!beaten)
				equitySum += 1.0 / tiedCount;
		}

		return equitySum / trials;
	}

	static function compareHandRank(a:{rank:Int, num1:Int, num2:Int}, b:{rank:Int, num1:Int, num2:Int}):Int
	{
		if (a.rank != b.rank)
			return a.rank - b.rank;
		if (a.num1 != b.num1)
			return a.num1 - b.num1;
		return a.num2 - b.num2;
	}

	function botDecideAction(seat:Int):PlayerAction
	{
		var p = players[seat];
		var toCall = currentBet - p.currentBet;
		var strength = handEquity(seat);
		var bluff = Math.random() < 0.08; // occasional bluff so strength isn't fully readable from behavior

		if (toCall <= 0)
		{
			var betChance = bluff ? 0.5 : strength * 0.9;

			if (checkPassiveRate(seat) > 0.7) // prevents cheat/hack of just spamming check to autowin
			{
				final isCooked = moveCount[seat].isStrong;

				if (!isCooked) betChance += 0.2; // attack his passive ahh
				else betChance -= 0.15; // maybe dont attack as much
			}
			betChance = Math.min(betChance, 1.0);

			if (Math.random() >= betChance)
				return Check;

			var sizeFactor = 0.3 + strength * 0.9; // stronger hands bet bigger
			var size = BIG_BLIND + Std.int(sizeFactor * (pot > 0 ? pot : BIG_BLIND * 2));
			return Bet(currentBet + size);
		}

		// strength is now a real win probability, so comparing it to pot odds directly
		// (plus a small safety margin) is the mathematically correct call/fold rule
		var potOdds = toCall / (pot + toCall);
		if (!bluff && strength < potOdds * 1.05)
			return Fold;

		if (bluff || strength > 0.6) // made the dealer care about how much he has instead of gambling the moment his cards are good -MT
		{
			var raiseSize = BIG_BLIND + Std.int((0.5 + strength) * BIG_BLIND * 3);

			if (strength >= 0.8) raiseSize = p.chips; // go all in
			else if (strength >= 0.6) raiseSize = Std.int(p.chips / 2); // be more careful and bet half of your chips
			else raiseSize = Std.int(Math.min(raiseSize, p.chips / 2)); // be cautious and don't bet more than half

			return Raise(p.currentBet + raiseSize); // oops it doesnt fully go all in sorry guys -MT
		}

		return Call;
	}

	function postBet(seat:Int, amount:Int)
	{
		var p = players[seat];
		var actual = Std.int(Math.min(amount, p.chips));

		p.chips -= actual;
		p.currentBet += actual;
		pot += actual;

		if (p.chips <= 0)
			p.isAllIn = true;

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

	/**
	 * True when nobody has a betting decision left this street, i.e. everyone is folded or all-in,
	 * or the single remaining player has nothing left to call.
	 */
	function bettingDone():Bool
	{
		var actors = [for (i in 0...players.length) if (!players[i].isOut && !players[i].folded && !players[i].isAllIn) i];
		if (actors.length == 0)
			return true;
		if (actors.length == 1)
			return players[actors[0]].currentBet >= currentBet;
		return false;
	}

	/**
	 * Returns the part of the highest bet that nobody matched to its owner. Without this, a player
	 * betting more than anyone can cover would lose the uncallable remainder into the pot.
	 */
	function refundUncalledBet()
	{
		var topSeat = -1;
		var top = -1;
		var second = 0;

		for (i in 0...players.length)
		{
			var bet = players[i].currentBet;
			if (bet > top)
			{
				second = top < 0 ? 0 : top;
				top = bet;
				topSeat = i;
			}
			else if (bet > second)
				second = bet;
		}

		if (topSeat == -1 || top - second <= 0)
			return;

		var excess = top - second;
		var p = players[topSeat];
		p.chips += excess;
		p.currentBet -= excess;
		pot -= excess;

		if (p.chips > 0)
			p.isAllIn = false;

		onPotChanged();
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
			new FlxTimer(timerManager).start(FlxG.random.float(0.7, 2.4), (_) -> takeBotTurn(seat));
	}

	function takeBotTurn(seat:Int)
	{
		if (seat != turnSeat)
			return;

		if (handleAction(seat, legalAction(seat, botDecideAction(seat))))
			return;

		// Last resort, so a bad decision can never leave the table stuck on this seat.
		var toCall = currentBet - players[seat].currentBet;
		handleAction(seat, toCall > 0 ? Fold : Check);
	}

	function advanceTurn()
	{
		var contenders = [for (p in players) if (!p.folded) p];
		if (contenders.length <= 1)
			return awardPotToRemaining();

		if (bettingDone() || allSettled())
			return advanceStreet();

		var next = nextToActSeat(turnSeat);
		if (next == -1)
			return advanceStreet();

		setTurn(next);
	}

	function advanceStreet()
	{
		refundUncalledBet();

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

		var next = bettingDone() ? -1 : nextToActSeat(dealerSeat);
		if (next == -1)
			return advanceStreet();

		setTurn(next);
	}

	function awardPotToRemaining()
	{
		refundUncalledBet();

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
		turnSeat = -1;
		onShowdown(results);
		onHandOver();
	}

	function runShowdown()
	{
		var contenders = [for (i in 0...players.length) if (!players[i].folded) i];
		var results = [
			for (seat in contenders)
				{seat: seat, rank: CardUtil.bestHandOf7(players[seat].holeCards.concat(community))} // how many cards the player has + how many cards are there on the table => used to find the best hands of these cards
		];

		results.sort((a, b) -> // sorts all players from best to worst (by checking the difference in signs and using it to decide if a should go before b or if b should go before a)
		{
			if (a.rank.rank != b.rank.rank)
				return b.rank.rank - a.rank.rank;
			if (a.rank.num1 != b.rank.num1)
				return b.rank.num1 - a.rank.num1;
			return b.rank.num2 - a.rank.num2;
		});

		var best = results[0].rank; // since results is best to worst, the best is the first item on the list
		var winners = results.filter(r -> // find anyone matching the best player, allows a tie though
			r.rank.rank == best.rank
			&& r.rank.num1 == best.num1
			&& r.rank.num2 == best.num2
		);

		var share = Std.int(pot / winners.length); // already helps me when i tie, it already shares the pot equally to all players
		var remainder = pot % winners.length; // modulo exists gng -MT

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
		turnSeat = -1;
		onShowdown(showdownResults);
		onHandOver();
	}
}
