package;

import backend.CardManager;
import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.util.FlxTimer;
import objects.Card;

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

class PlayState extends FlxState
{
	static inline var SMALL_BLIND = 10;
	static inline var BIG_BLIND = 20;
	static inline var STARTING_CHIPS = 1000;

	static inline var POT_X = 596.0;
	static inline var POT_Y = 260.0;
	static inline var HOLE_Y = 520.0;
	static inline var COMMUNITY_Y = 260.0;

	var players:Array<PokerPlayer> = [];
	var community:Array<CardData> = [];
	var pot:Int = 0;
	var currentBet:Int = 0;
	var dealerSeat:Int = 3;
	var turnSeat:Int = -1;
	var street:Street = Waiting;

	var deck:Array<CardData> = [];
	var actedThisRound:Array<Bool> = [false, false, false, false];

	var holeCardSprites:Array<Card> = [];
	var communityCardSprites:Array<Card> = [];

	var potText:FlxText;
	var chipsText:FlxText;
	var streetText:FlxText;

	var foldBtn:FlxButton;
	var checkCallBtn:FlxButton;
	var raiseMinusBtn:FlxButton;
	var raisePlusBtn:FlxButton;
	var raiseAmountText:FlxText;
	var raiseConfirmBtn:FlxButton;

	var pendingRaiseBB:Int = 1;

	override public function create()
	{
		super.create();

		potText = new FlxText(POT_X - 60, POT_Y + 130, 200, "Pot: 0", 20);
		add(potText);

		chipsText = new FlxText(20, HOLE_Y + 10, 300, "Chips: 0", 20);
		add(chipsText);

		streetText = new FlxText(20, 20, 400, "Street: waiting", 20);
		add(streetText);

		foldBtn = new FlxButton(300, 650, "Fold", () -> {
			disableActionButtons();
			handleAction(0, Fold);
		});
		add(foldBtn);

		checkCallBtn = new FlxButton(420, 650, "Check", () -> {
			disableActionButtons();
			var action = (currentBet - players[0].currentBet) > 0 ? Call : Check;
			handleAction(0, action);
		});
		add(checkCallBtn);

		raiseMinusBtn = new FlxButton(600, 650, "-", () -> {
			if (pendingRaiseBB > 1)
				pendingRaiseBB--;
			updateRaiseAmountText();
		});
		add(raiseMinusBtn);

		raiseAmountText = new FlxText(650, 655, 160, "0", 16);
		raiseAmountText.alignment = CENTER;
		add(raiseAmountText);

		raisePlusBtn = new FlxButton(810, 650, "+", () -> {
			pendingRaiseBB++;
			updateRaiseAmountText();
		});
		add(raisePlusBtn);

		raiseConfirmBtn = new FlxButton(900, 650, "Bet/Raise", () -> {
			disableActionButtons();
			var target = currentBet + pendingRaiseBB * BIG_BLIND;
			var action = currentBet > 0 ? Raise(target) : Bet(target);
			handleAction(0, action);
		});
		add(raiseConfirmBtn);

		players = [
			{name: "You", isBot: false, chips: STARTING_CHIPS, currentBet: 0, folded: false, isAllIn: false, holeCards: [], isOut: false},
			{name: "Bot 1", isBot: true, chips: STARTING_CHIPS, currentBet: 0, folded: false, isAllIn: false, holeCards: [], isOut: false},
			{name: "Bot 2", isBot: true, chips: STARTING_CHIPS, currentBet: 0, folded: false, isAllIn: false, holeCards: [], isOut: false},
			{name: "Bot 3", isBot: true, chips: STARTING_CHIPS, currentBet: 0, folded: false, isAllIn: false, holeCards: [], isOut: false},
		];

		disableActionButtons();
		startHand();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	function playersWithChips():Int
	{
		var n = 0;
		for (p in players)
			if (p.chips > 0)
				n++;
		return n;
	}

	function startHand()
	{
		community = [];
		pot = 0;
		currentBet = 0;
		street = Preflop;
		deck = CardManager.freshShuffledDeck();

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

		for (i in 0...4)
			actedThisRound[i] = false;

		var next = nextToActSeat(bbSeat);
		if (next == -1)
			advanceStreet();
		else
		{
			turnSeat = next;
			onTurnChanged(turnSeat);
		}
	}

	function handleAction(seat:Int, action:PlayerAction):Bool
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
				if (seat == 0)
					killHoleCards();

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
				for (i in 0...4)
					actedThisRound[i] = false;
		}

		actedThisRound[seat] = true;
		onPlayerActed(seat, action);

		advanceTurn();
		return true;
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

		for (i in 0...4)
		{
			seat = (seat + 1) % 4;
			if (!players[seat].isOut)
				return seat;
		}

		return from;
	}

	function nextToActSeat(from:Int):Int
	{
		var seat = from;

		for (i in 0...4)
		{
			seat = (seat + 1) % 4;
			var p = players[seat];
			if (!p.isOut && !p.folded && !p.isAllIn)
				return seat;
		}

		return -1;
	}

	function allSettled():Bool
	{
		for (i in 0...4)
		{
			var p = players[i];
			if (p.folded || p.isAllIn)
				continue;
			if (!actedThisRound[i] || p.currentBet != currentBet)
				return false;
		}

		return true;
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

		turnSeat = next;
		onTurnChanged(turnSeat);
	}

	function advanceStreet()
	{
		for (i in 0...4)
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

		turnSeat = next;
		onTurnChanged(turnSeat);
	}

	function awardPotToRemaining()
	{
		var winnerSeat = -1;
		for (i in 0...4)
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
		var contenders = [for (i in 0...4) if (!players[i].folded) i];
		var results = [
			for (seat in contenders)
				{seat: seat, rank: CardManager.bestHandOf7(players[seat].holeCards.concat(community))}
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
				handText: CardManager.formatCombo(w.rank),
				winnings: winnings,
			});
		}

		pot = 0;
		onShowdown(showdownResults);
		onHandOver();
	}

	function onDeal()
	{
		killHoleCards();
		killCommunityCards();

		var human = players[0];

		for (i in 0...human.holeCards.length)
		{
			var card = new Card();
			card.x = POT_X;
			card.y = POT_Y;
			add(card);
			holeCardSprites.push(card);

			var data = human.holeCards[i];
			card.x = 560 + (i * 100);
			card.y = HOLE_Y;
			card.reveal(data, true);
		}

		streetText.text = 'Street: $street';
		trace('New hand. Dealer seat $dealerSeat.');
		refreshChipsText();
	}

	function onCommunityCard(data:CardData, index:Int)
	{
		var card = new Card();
		card.x = POT_X;
		card.y = POT_Y;
		add(card);
		communityCardSprites.push(card);

		card.x = 396.0 + index * 100;
		card.y = COMMUNITY_Y;
		card.reveal(data, true);
		//FlxTween.tween(card, {x: 396.0 + index * 100, y: COMMUNITY_Y}, 0.35, {onComplete: (_) -> card.reveal(data, true)});

		streetText.text = 'Street: $street';
	}

	function onPotChanged()
	{
		potText.text = 'Pot: $pot';
		refreshChipsText();
	}

	function onTurnChanged(seat:Int)
	{
		var p = players[seat];
		if (p.isBot)
		{
			disableActionButtons();
			new FlxTimer().start(0.6, (_) -> handleAction(seat, botDecideAction(seat)));
		}
		else
			enableHumanActionButtons();
	}

	function onPlayerActed(seat:Int, action:PlayerAction)
	{
		var p = players[seat];
		trace('${p.name} -> ${actionLabel(action)} | bet=${p.currentBet} chips=${p.chips} pot=$pot');
		refreshChipsText();
	}

	function actionLabel(action:PlayerAction):String
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

	function onShowdown(results:Array<ShowdownResult>)
	{
		disableActionButtons();
		if (results.length == 0)
			trace("Hand over");
		else
			trace([for (r in results) '${r.name} wins ${r.winnings} (${r.handText})'].join("\n"));
	}

	function onHandOver()
	{
		killHoleCards();

		new FlxTimer().start(2.5, (_) ->
		{
			if (playersWithChips() < 2)
				FlxG.resetState();
			else
				startHand();
		});
	}

	function killHoleCards()
	{
		for (c in holeCardSprites.copy())
		{
			holeCardSprites.remove(c);
			FlxTween.cancelTweensOf(c);
			c.destroy();
		}
	}

	function killCommunityCards()
	{
		for (c in communityCardSprites.copy())
		{
			communityCardSprites.remove(c);
			FlxTween.cancelTweensOf(c);
			c.destroy();
		}
	}

	function refreshChipsText()
	{
		chipsText.text = 'Chips: ${players[0].chips}';
	}

	function enableHumanActionButtons()
	{
		var human = players[0];
		var toCall = currentBet - human.currentBet;
		checkCallBtn.text = toCall > 0 ? 'Call $toCall' : "Check";

		pendingRaiseBB = 1;
		updateRaiseAmountText();

		foldBtn.visible = foldBtn.active = true;
		checkCallBtn.visible = checkCallBtn.active = true;
		raiseMinusBtn.visible = raiseMinusBtn.active = true;
		raisePlusBtn.visible = raisePlusBtn.active = true;
		raiseConfirmBtn.visible = raiseConfirmBtn.active = true;
	}

	function disableActionButtons()
	{
		foldBtn.visible = foldBtn.active = false;
		checkCallBtn.visible = checkCallBtn.active = false;
		raiseMinusBtn.visible = raiseMinusBtn.active = false;
		raisePlusBtn.visible = raisePlusBtn.active = false;
		raiseConfirmBtn.visible = raiseConfirmBtn.active = false;
	}

	function updateRaiseAmountText()
	{
		var target = currentBet + pendingRaiseBB * BIG_BLIND;
		raiseAmountText.text = '$target';
	}
}
