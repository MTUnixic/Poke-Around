package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import menus.CardsRevealScreen;
import menus.GameOverSubState;
import menus.PauseMenu;
import objects.Briefcase;
import objects.Card;
import objects.DealerSprite;
import objects.ItemCard;
import objects.Table;
import util.CardUtil;
import util.MouseUtil;
import util.SpriteButtonUtil;

class PlayState extends BackgrndState
{
	static inline var ACTION_BTN_FRAME_W = 70;
	static inline var ACTION_BTN_FRAME_H = 50;
	static inline var ACTION_BTN_SCALE = 2.0;
	static inline var ACTION_BTN_W = 140.0; // ACTION_BTN_FRAME_W * ACTION_BTN_SCALE
	static inline var ACTION_BTN_H = 100.0; // ACTION_BTN_FRAME_H * ACTION_BTN_SCALE
	static inline var ACTION_BTN_GAP = 20;
	static inline var ACTION_ROW_MARGIN_BOTTOM = 10;

	static inline var SMALL_BTN_FRAME_W = 50;
	static inline var SMALL_BTN_FRAME_H = 50;
	static inline var SMALL_BTN_SCALE = 0.75;
	static inline var SMALL_BTN_W = 37.5; // SMALL_BTN_FRAME_W * SMALL_BTN_SCALE
	static inline var SMALL_BTN_H = 37.5; // SMALL_BTN_FRAME_H * SMALL_BTN_SCALE
	static inline var AMOUNT_TEXT_W = 80;
	static inline var AMOUNT_TEXT_GAP = 10;

	var table:Table;
	var localPlayer:PokerPlayer;

	var holeCardSprites:Array<Card> = [];
	var communityCardSprites:Array<Card> = [];

	var potText:FlxText;
	var chipsText:FlxText;
	var streetText:FlxText;

	var historyTexts:Array<FlxText> = [];

	var foldBtn:SpriteButtonUtil;
	var checkCallBtn:SpriteButtonUtil;
	var callAmountText:FlxText;

	var raiseMinusBtn:SpriteButtonUtil;
	var raisePlusBtn:SpriteButtonUtil;
	var raiseAmountText:FlxText;
	var raiseConfirmBtn:SpriteButtonUtil;

	var briefcase:Briefcase;

	var pendingRaiseBB:Int = 1;
	var pauseButton:FlxSprite;

	var dealerSprites:Array<DealerSprite> = [];

	var timers:FlxTimerManager;

	var lastBriefcaseHover:Bool = false;
	var breifcaseUpdatable:Bool = true;

	var playerItems:Array<ItemCard> = [];
	var itemHovered:Array<Bool> = [];

	var handStartChips:Int = 0;
	var localFolded:Bool = false;

	var goldenBulletArmed:Bool = false;

	var cardDescrBackground:FlxSprite;
	var cardDescrIcon:FlxSprite;
	var cardDescrText:FlxText;

	override public function create()
	{
		super.create();

		timers = new FlxTimerManager();
		add(timers);

		potText = new FlxText(600, 420, 200, "Pot: 0", 20);
		potText.color = 0xffcdf7e2;
		add(potText);

		chipsText = new FlxText(25, 60, 300, "Chips: 0", 20);
		chipsText.color = 0xff6d2c45;
		add(chipsText);

		streetText = new FlxText(20, 20, 400, "Street: waiting", 20);
		streetText.color = 0xff6d2c45;
		add(streetText);

		var actionRowWidth = ACTION_BTN_W * 3 + ACTION_BTN_GAP * 2;
		var actionRowX = (FlxG.width - actionRowWidth) / 2;
		var actionRowY = FlxG.height - ACTION_BTN_H - ACTION_ROW_MARGIN_BOTTOM;
		var amountRowY = actionRowY - SMALL_BTN_H - AMOUNT_TEXT_GAP;

		var foldX = actionRowX;
		var checkCallX = actionRowX + ACTION_BTN_W + ACTION_BTN_GAP;
		var raiseConfirmX = actionRowX + (ACTION_BTN_W + ACTION_BTN_GAP) * 2;

		foldBtn = new SpriteButtonUtil(foldX, actionRowY, null, () ->
		{
			disableActionButtons();
			if (!table.handleAction(table.localSeat, Fold))
				enableHumanActionButtons();
		});
		foldBtn.loadGraphic("assets/images/pokuhbuttons.png", true, ACTION_BTN_FRAME_W, ACTION_BTN_FRAME_H);
		foldBtn.animation.add("button", [1]);
		foldBtn.animation.play("button");
		foldBtn.setGraphicSize(Std.int(ACTION_BTN_W), Std.int(ACTION_BTN_H));
		foldBtn.updateHitbox();
		add(foldBtn);

		checkCallBtn = new SpriteButtonUtil(checkCallX, actionRowY, null, () ->
		{
			disableActionButtons();
			var action = (table.currentBet - localPlayer.currentBet) > 0 ? Call : Check;
			if (!table.handleAction(table.localSeat, action))
				enableHumanActionButtons();
		});
		checkCallBtn.loadGraphic("assets/images/pokuhbuttons.png", true, ACTION_BTN_FRAME_W, ACTION_BTN_FRAME_H);
		checkCallBtn.animation.add("call", [0]);
		checkCallBtn.animation.add("check", [3]);
		checkCallBtn.animation.play("check");
		checkCallBtn.setGraphicSize(Std.int(ACTION_BTN_W), Std.int(ACTION_BTN_H));
		checkCallBtn.updateHitbox();
		add(checkCallBtn);

		callAmountText = new FlxText(checkCallX + ACTION_BTN_W / 2 - AMOUNT_TEXT_W / 2, 0, AMOUNT_TEXT_W, "", 24);
		callAmountText.alignment = CENTER;
		callAmountText.y = amountRowY + (SMALL_BTN_H - callAmountText.height) / 2;
		add(callAmountText);

		raiseAmountText = new FlxText(raiseConfirmX + ACTION_BTN_W / 2 - AMOUNT_TEXT_W / 2, 0, AMOUNT_TEXT_W, "$0", 24);
		raiseAmountText.alignment = CENTER;
		raiseAmountText.y = amountRowY + (SMALL_BTN_H - raiseAmountText.height) / 2;

		raiseMinusBtn = new SpriteButtonUtil(raiseAmountText.x - SMALL_BTN_W - AMOUNT_TEXT_GAP, amountRowY, null, () ->
		{
			if (pendingRaiseBB > 1)
				pendingRaiseBB--;
			updateRaiseAmountText();
		});
		raiseMinusBtn.loadGraphic("assets/images/pokuhbuttonssmall.png", true, SMALL_BTN_FRAME_W, SMALL_BTN_FRAME_H);
		raiseMinusBtn.animation.add("button", [0]);
		raiseMinusBtn.animation.play("button");
		raiseMinusBtn.setGraphicSize(Std.int(SMALL_BTN_W), Std.int(SMALL_BTN_H));
		raiseMinusBtn.updateHitbox();
		add(raiseMinusBtn);

		add(raiseAmountText);

		raisePlusBtn = new SpriteButtonUtil(raiseAmountText.x + AMOUNT_TEXT_W + AMOUNT_TEXT_GAP, amountRowY, null, () ->
		{
			pendingRaiseBB++;
			updateRaiseAmountText();
		});
		raisePlusBtn.loadGraphic("assets/images/pokuhbuttonssmall.png", true, SMALL_BTN_FRAME_W, SMALL_BTN_FRAME_H);
		raisePlusBtn.animation.add("button", [1]);
		raisePlusBtn.animation.play("button");
		raisePlusBtn.setGraphicSize(Std.int(SMALL_BTN_W), Std.int(SMALL_BTN_H));
		raisePlusBtn.updateHitbox();
		add(raisePlusBtn);

		raiseConfirmBtn = new SpriteButtonUtil(raiseConfirmX, actionRowY, null, () ->
		{
			disableActionButtons();
			var target = table.currentBet + pendingRaiseBB * Table.BIG_BLIND;
			var action = table.currentBet > 0 ? Raise(target) : Bet(target);
			if (!table.handleAction(table.localSeat, action))
				enableHumanActionButtons();
		});
		raiseConfirmBtn.loadGraphic("assets/images/pokuhbuttons.png", true, ACTION_BTN_FRAME_W, ACTION_BTN_FRAME_H);
		raiseConfirmBtn.animation.add("bet", [2]);
		raiseConfirmBtn.animation.add("raise", [4]); // TODO: make functionality for bet and raise pls -MT
		raiseConfirmBtn.animation.play("bet");
		raiseConfirmBtn.setGraphicSize(Std.int(ACTION_BTN_W), Std.int(ACTION_BTN_H));
		raiseConfirmBtn.updateHitbox();
		add(raiseConfirmBtn);

		disableActionButtons();

		briefcase = new Briefcase(FlxG.width-240, FlxG.height-60);
		add(briefcase);

		table = new Table();
		table.timerManager = timers;

		table.addPlayer("Player", Local);
		var dealerIndex = table.addPlayer("Dealer", Bot);

		var botPlayer = new DealerSprite();
		botPlayer.x = FlxG.width/2 - botPlayer.width/2;
		botPlayer.y = 70;
		dealerSprites[dealerIndex] = botPlayer;
		insert(90, botPlayer);

		localPlayer = table.players[table.localSeat];

		for (i in 0...3)
		{
			var itemCard = new ItemCard(50 + i * 50, 2);
			itemCard.alpha = 0;
			FlxTimer.wait(0.8 + i * 0.25, () -> FlxTween.tween(itemCard, {alpha: 1}, 0.5, {ease: FlxEase.quadOut}));
			briefcase.addCard(itemCard);
			playerItems.push(itemCard);
		}
		itemHovered = [for (_ in playerItems) false];


		cardDescrBackground = new FlxSprite();
		cardDescrBackground.loadGraphic("assets/images/pokuhpopup.png");
		cardDescrBackground.setGraphicSize(cardDescrBackground.width * 3, cardDescrBackground.height * 3);
		cardDescrBackground.updateHitbox();
		cardDescrBackground.x = FlxG.width - cardDescrBackground.width - 10;
		cardDescrBackground.y = 240;
		cardDescrBackground.alpha = 0;
		add(cardDescrBackground);

		cardDescrIcon = new FlxSprite();
		cardDescrIcon.loadGraphic("assets/images/pokuhcaards.png", true, 64, 80);
		cardDescrIcon.animation.add("DesignManual", [1]);
		cardDescrIcon.animation.add("Calculator", [2]);
		cardDescrIcon.animation.add("Marker", [3]);
		cardDescrIcon.animation.add("GoldenBullet", [4]);
		cardDescrIcon.animation.add("Intimidation", [5]);
		cardDescrIcon.x = cardDescrBackground.x + 20;
		cardDescrIcon.y = cardDescrBackground.y + 20;
		cardDescrIcon.alpha = 0;
		add(cardDescrIcon);

		cardDescrText = new FlxText(cardDescrIcon.x + cardDescrIcon.width + 10, cardDescrIcon.y, 300, "", 16);
		cardDescrText.alpha = 0;
		add(cardDescrText);

		table.onDeal = onDeal;
		table.onCommunityCard = onCommunityCard;
		table.onPotChanged = onPotChanged;
		table.onTurnChanged = onTurnChanged;
		table.onPlayerActed = onPlayerActed;
		table.onShowdown = onShowdown;
		table.onHandOver = onHandOver;

		table.startHand();

		pauseButton = new SpriteButtonUtil(0, 8, null, () -> openSubState(new PauseMenu()));
		pauseButton.loadGraphic('assets/images/pokuhbuttonssmall.png', true, 50, 50);
		pauseButton.animation.add("button", [3]);
		pauseButton.animation.play("button");
		pauseButton.x = FlxG.width - pauseButton.width - 8;
		add(pauseButton);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.NINE)
			grantRandomItem();

		MouseUtil.mouseCamera(36, 1.025);
		doBreifcase();
		doItemCards();

		cardDescrIcon.alpha = cardDescrBackground.alpha;
		cardDescrText.alpha = cardDescrBackground.alpha;
	}

	function doItemCards()
	{
		for (i in 0...playerItems.length)
		{
			var card = playerItems[i];
			var hovering = FlxG.mouse.overlaps(card);

			if (hovering != itemHovered[i])
			{
				itemHovered[i] = hovering;

				if (hovering && card.value != null)
					showCardDescription(card.value);
				else
					hideCardDescription();
			}

			if (MouseUtil.justClicked(card))
			{
				if (card.value != null)
				{
					hideCardDescription();
					useItem(card.value);
					card.use();
				}
			}
		}
	}

	function showCardDescription(item:PlayerItem)
	{
		var descr = itemDescription(item);
		cardDescrIcon.animation.play(descr.name);
		cardDescrText.text = descr.text;

		FlxTween.cancelTweensOf(cardDescrBackground);
		FlxTween.tween(cardDescrBackground, {alpha: 1}, 0.25, {ease: FlxEase.quadOut});
	}

	function hideCardDescription()
	{
		FlxTween.cancelTweensOf(cardDescrBackground);
		FlxTween.tween(cardDescrBackground, {alpha: 0}, 0.25, {ease: FlxEase.quadIn});
	}

	function itemDescription(item:PlayerItem):{name:String, text:String}
	{
		return switch (item)
		{
			case DesignManual: {name: "DesignManual", text: "You inspect the design manual for this game. It reveals the next 3 community cards."};
			case Calculator: {name: "Calculator", text: "Increases your opponent's dept, focing them to bet double. High risk, high reward."};
			case Marker: {name: "Marker", text: "You use a magic marker to change the type of your weakest hole card with the strongest card from your opponent's hand."};
			case GoldenBullet: {name: "GoldenBullet", text: "Your life flash before your eyes, as you get saved from elimination with 100 extra chips. Wasted if unused, plan carefully."};
			case Intimidation: {name: "Intimidation", text: "You cock your pistol from your back pouch, your opponent backs off for a while."};
		}
	}

	function useItem(item:PlayerItem)
	{
		switch (item)
		{
			case DesignManual:
				var nextCards = table.peekNextCards(3);
				openSubState(new CardsRevealScreen(nextCards));

			case Calculator:
				table.armDoubleMinRaise();
				addHistoryText("Calculator readied: next raise must be doubled!");

			case Marker:
				var swap = table.replaceWeakestHoleCard(table.localSeat);
				if (swap != null)
				{
					if (holeCardSprites[swap.index] != null)
						holeCardSprites[swap.index].reveal(swap.card, true);
					addHistoryText('You upgrade your weakest card to ${CardUtil.formatCard(swap.card)}!');
				}

			case GoldenBullet:
				goldenBulletArmed = true;
				addHistoryText("Golden Bullet armed for this hand!");

			case Intimidation:
				table.armForcedFold(1 - table.localSeat);
				addHistoryText("Intimidation readied: opponent folds next turn!");
		}
	}

	function doBreifcase() // brought back breifcase + code looked like ahh so i cleaned it up -MT
	{
		if (!breifcaseUpdatable) return;
		if (FlxG.mouse.overlaps(briefcase) == lastBriefcaseHover) return;

		lastBriefcaseHover = FlxG.mouse.overlaps(briefcase);
		breifcaseUpdatable = false;

		if (FlxG.mouse.overlaps(briefcase)) {
			FlxTween.tween(briefcase, {y: FlxG.height-140}, 0.75, {
				ease: FlxEase.quadOut,
				onComplete: function(tween:FlxTween) breifcaseUpdatable = true
			});
		} else {
			FlxTween.tween(briefcase, {y: FlxG.height-50}, 0.5, {
				ease: FlxEase.quadIn,
				onComplete: function(tween:FlxTween) breifcaseUpdatable = true
			});
		}
	}

	function onDeal()
	{
		addHistoryText("New hand dealt.");

		handStartChips = localPlayer.chips;
		localFolded = false;

		killHoleCards();
		killCommunityCards();

		for (i in 0...localPlayer.holeCards.length)
		{
			var card = new Card();
			card.x = 90 + (i * 100);
			card.y = FlxG.height;
			card.z = 90;
			add(card);
			holeCardSprites.push(card);

			var data = localPlayer.holeCards[i];

			FlxTween.tween(card, { y: FlxG.height - card.height - 30 }, 0.75, { ease: FlxEase.quadOut, onComplete: function(tween:FlxTween) {
				card.reveal(data, true);
			}});
		}

		for (plr in table.players)
		{
			if (plr == localPlayer)
				continue;

			if (plr.isOut)
				continue;

			var plrSprite = dealerSprites[table.players.indexOf(plr)];
			plrSprite?.grabCard();
		}

		streetText.text = 'Street: ${table.street}';
		refreshChipsText();
	}

	function onCommunityCard(data:CardData, index:Int)
	{
		var card = new Card();
		add(card);
		communityCardSprites.push(card);

		card.x = 396.0 + index * 100;
		var restY = 310.0;
		card.z = -150;

		// frankly i have no idea what is going on here, but it works so dont bother with it lol

		card.cameraOffsetY = card.height / 2;
		card.angleX = -25;

		var t = (index - 2) / 2;
		card.angleY = -t * 20;
		card.cameraOffsetX = -t * (card.width / 2);

		card.y = restY - 400;
		FlxTween.tween(card, { y: restY }, 0.4, { ease: FlxEase.quadIn, onComplete: function(tween:FlxTween) {
			card.reveal(data, false);
		}});

		streetText.text = 'Street: ${table.street}';
	}

	function onPotChanged()
	{
		potText.text = 'Pot: ${table.pot}';
		refreshChipsText();
	}

	function onTurnChanged(seat:Int)
	{
		FlxTween.cancelTweensOf(squa);
		FlxTween.cancelTweensOf(glow);

		var targetColor:FlxColor = table.players[seat].isBot ? 0xff6d758d : 0xff1a7a3e;

		alphalessColorTween(squa, targetColor);
		alphalessColorTween(glow, targetColor);

		if (table.players[seat].isBot)
			dealerSprites[seat]?.think();

		if (seat < 0 || table.players[seat].isBot)
			disableActionButtons();
		else
			enableHumanActionButtons();
	}

	inline function alphalessColorTween(sprite:FlxSprite, targetColor:FlxColor, ?time:Float = 0.75, ?options:TweenOptions) // colors tweens are 0xAArrggbb so if alpha is FF alpha will be forcefully tweened to 1 -MT
	{
		var oldRed = sprite.color.red;
		var oldGreen = sprite.color.green;
		var oldBlue = sprite.color.blue;

		options ??= {ease: FlxEase.quadOut}; // if (options == null) options = {ease: FlxEase.quadOut};

		FlxTween.num(oldRed, targetColor.red, time, options, value -> {
			oldRed = Std.int(value);
			sprite.color = FlxColor.fromRGB(oldRed, oldGreen, oldBlue);
		});
		FlxTween.num(oldGreen, targetColor.green, time, options, value -> {
			oldGreen = Std.int(value);
			sprite.color = FlxColor.fromRGB(oldRed, oldGreen, oldBlue);
		});
		FlxTween.num(oldBlue, targetColor.blue, time, options, value -> {
			oldBlue = Std.int(value);
			sprite.color = FlxColor.fromRGB(oldRed, oldGreen, oldBlue);
		});
	}

	function onPlayerActed(seat:Int, action:PlayerAction)
	{
		var p = table.players[seat];

		switch (action)
		{
			case Fold:
				dealerSprites[seat]?.fold();
			case Check, Call:
				dealerSprites[seat]?.call();
			case Bet(t), Raise(t):
				dealerSprites[seat]?.raise(t, t >= p.chips);
		}

		if (seat == table.localSeat)
			switch (action)
			{
				case Fold:
					killHoleCards();
					localFolded = true;
				default:
			}

		addHistoryText(switch (action)
		{
			case Fold: '${p.name} folds';
			case Check: '${p.name} checks';
			case Call: '${p.name} calls';
			case Bet(target): '${p.name} bets $$$target';
			case Raise(target): '${p.name} raises to $$$target';
		});

		if (p.isAllIn)
			addHistoryText('${p.name} is all in with $$${p.currentBet}!');

		refreshChipsText();
	}

	function onShowdown(results:Array<ShowdownResult>)
	{
		disableActionButtons();
		if (results.length == 0)
			addHistoryText("Hand over.");
		else
			for (r in results)
				addHistoryText('${r.name} wins $$${r.winnings} (${r.handText})');

		var localWon = results.filter(r -> r.seat == table.localSeat).length > 0;
		var amountLost = handStartChips - localPlayer.chips;

		if (!localWon && !localFolded && amountLost > 100)
			grantRandomItem();
	}

	function grantRandomItem()
	{
		var emptySlots = playerItems.filter(c -> c.value == null);
		if (emptySlots.length == 0)
			return;

		var items = [DesignManual, Calculator, Marker, GoldenBullet, Intimidation];
		emptySlots[0].setItem(FlxG.random.getObject(items));
	}

	function onHandOver()
	{
		killHoleCards();

		new FlxTimer(timers).start(2.5, (_) ->
		{
			if (goldenBulletArmed)
			{
				goldenBulletArmed = false; // one hand only, win or lose - "next round will be useless"
				if (localPlayer.chips <= 0)
				{
					table.addChips(table.localSeat, 100);
					addHistoryText("Golden Bullet saves you with 100 chips!");
				}
			}

			var opponent = table.players[1 - table.localSeat];
			var playerWon = opponent.chips <= 0 || localPlayer.chips >= 2400;
			var playerLost = localPlayer.chips <= 0 || opponent.chips >= 2400;

			if (playerWon || playerLost)
			{
				if (playerWon)
				{
					for (s in dealerSprites)
					{
						if (s == null)
							continue;
						
						s?.preLose();
						FlxTimer.wait(1.5, () -> s?.lose());
						FlxTimer.wait(2, () -> {
							FlxFlicker.flicker(s, 1, 0.04, false);
						});
					}
				}
				else
				{
					for (s in dealerSprites)
						s?.win();
				}
				openSubState(new GameOverSubState(playerWon));
			}
			else
				table.startHand();
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
		chipsText.text = 'Chips: ${localPlayer.chips}';
	}

	function addHistoryText(msg:String)
	{
		for (t in historyTexts)
		{
			FlxTween.completeTweensOf(t);
			FlxTween.tween(t, {y: t.y - 22}, 0.3, {ease: FlxEase.quadOut});
		}

		var text = new FlxText(40, FlxG.height - 170, /*260*/400, msg, 16);
		text.color = 0xffcdf7e2;
		text.alpha = 0;
		add(text);
		historyTexts.push(text);

		FlxTween.tween(text, {alpha: 1}, 0.2, {ease: FlxEase.quadOut});

		new FlxTimer(timers).start(3.0, (_) ->
		{
			FlxTween.tween(text, {alpha: 0}, 0.5, {ease: FlxEase.quadIn, onComplete: (_) ->
			{
				historyTexts.remove(text);
				text.destroy();
			}});
		});
	}

	function enableHumanActionButtons()
	{
		var toCall = table.currentBet - localPlayer.currentBet;
		if (toCall > 0)
		{
			checkCallBtn.animation.play("call");
			callAmountText.text = '$$$toCall';
		}
		else
		{
			checkCallBtn.animation.play("check");
			callAmountText.text = "";
		}

		pendingRaiseBB = 1;
		updateRaiseAmountText();

		foldBtn.visible = foldBtn.active = true;
		checkCallBtn.visible = checkCallBtn.active = true;
		callAmountText.visible = true;
		raiseMinusBtn.visible = raiseMinusBtn.active = true;
		raisePlusBtn.visible = raisePlusBtn.active = true;
		raiseConfirmBtn.visible = raiseConfirmBtn.active = true;
		raiseAmountText.visible = true;
	}

	function disableActionButtons()
	{
		foldBtn.visible = foldBtn.active = false;
		checkCallBtn.visible = checkCallBtn.active = false;
		callAmountText.visible = false;
		raiseMinusBtn.visible = raiseMinusBtn.active = false;
		raisePlusBtn.visible = raisePlusBtn.active = false;
		raiseConfirmBtn.visible = raiseConfirmBtn.active = false;
		raiseAmountText.visible = false;
	}

	function updateRaiseAmountText()
	{
		var target = table.currentBet + pendingRaiseBB * Table.BIG_BLIND;
		raiseAmountText.text = '$$$target';
	}
}

enum PlayerItem
{
	/**
		Reveals the next 3 community cards
	**/
	DesignManual;

	/**
		The next player must raise the bet to at least double the previous raise (or 20)
	**/
	Calculator;

	/**
		Replaces your weakest card with the strongest card present in the current hand
	**/
	Marker;

	/**
		saves you from elimination by giving you 100 extra chips upon losing all credits, but only works if you lose to the current round, next round will be useless
	**/
	GoldenBullet;

	/**
		Makes the next player automatically fold their hand
	**/
	Intimidation;
}