package;

import flixel.FlxG;
import flixel.FlxSprite;
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
import objects.TableManager;
import util.AudioUtil;
import util.CardUtil;
import util.MouseUtil;
import util.SpriteButtonUtil;

class PlayState extends BackgrndState
{
	static inline var ACTION_BTTN_FRAME_W = 70;
	static inline var ACTION_BTTN_FRAME_H = 50;
	static inline var ACTION_BTTN_SCALE = 2.0;
	static inline var ACTION_BTTN_W = 140.0; // ACTION_BTTN_FRAME_W * ACTION_BTTN_SCALE
	static inline var ACTION_BTTN_H = 100.0; // ACTION_BTTN_FRAME_H * ACTION_BTTN_SCALE
	static inline var ACTION_BTTN_GAP = 20;
	static inline var ACTION_ROW_MARGIN_BOTTOM = 10;

	static inline var SMALL_BTTN_FRAME_W = 50;
	static inline var SMALL_BTTN_FRAME_H = 50;
	static inline var SMALL_BTTN_SCALE = 0.75;
	static inline var SMALL_BTTN_W = 37.5; // SMALL_BTTN_FRAME_W * SMALL_BTTN_SCALE
	static inline var SMALL_BTTN_H = 37.5; // SMALL_BTTN_FRAME_H * SMALL_BTTN_SCALE
	static inline var AMOUNT_TEXT_W = 96;
	static inline var AMOUNT_TEXT_GAP = 10;

	var table:TableManager;
	var localPlayer:PokerPlayer;

	var holeCardSprites:Array<Card> = [];
	var communityCardSprites:Array<Card> = [];

	var potText:FlxText;
	var localChipsText:FlxText;
	var dealerChipsText:FlxText;
	var streetText:FlxText;

	var historyTexts:Array<FlxText> = [];

	var foldBttn:SpriteButtonUtil;
	var checkCallBttn:SpriteButtonUtil;
	var callAmountText:FlxText;

	var raiseMinusBttn:SpriteButtonUtil;
	var raisePlusBttn:SpriteButtonUtil;
	var raiseAmountText:FlxText;
	var raiseConfirmBttn:SpriteButtonUtil;

	var briefcase:Briefcase;

	var pendingRaiseBB:Int = 1;
	var pauseButton:FlxSprite;

	var dealerSprites:Array<DealerSprite> = [];
	var dealerSeat:Int;

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

	var comboNameText:FlxText;

	var hoverBttns:Array<FlxSprite> = [];

	override public function create()
	{
		super.create();

		addVisualizer(AudioUtil.gameMusic);
		visualizer.alphaMax = 0.2;

		timers = new FlxTimerManager();
		add(timers);

		potText = new FlxText(600, 420, 200, "Pot: 0", 20);
		potText.color = 0xffcdf7e2;
		add(potText);

		streetText = new FlxText(20, 20, 400, "Street: waiting", 20);
		streetText.color = 0xff6d2c45;
		add(streetText);

		localChipsText = new FlxText(20, 80, 300, "Your Chips: $0", 20);
		localChipsText.color = 0xff71413b;
		add(localChipsText);

		dealerChipsText = new FlxText(20, 120, 300, "Dealer's Chips: $0", 20);
		dealerChipsText.color = 0xff6d758d;
		add(dealerChipsText);

		comboNameText = new FlxText(-24, 200, 300, "(waiting for card river..)", 20);
		comboNameText.color = 0xff6d2c45;
		comboNameText.alignment = CENTER;
		comboNameText.alpha = 0.6;
		add(comboNameText);

		var actionRowWidth = ACTION_BTTN_W * 3 + ACTION_BTTN_GAP * 2;
		var actionRowX = (FlxG.width - actionRowWidth) / 2;
		var actionRowY = FlxG.height - ACTION_BTTN_H - ACTION_ROW_MARGIN_BOTTOM;
		var amountRowY = actionRowY - SMALL_BTTN_H - AMOUNT_TEXT_GAP;

		var foldX = actionRowX;
		var checkCallX = actionRowX + ACTION_BTTN_W + ACTION_BTTN_GAP;
		var raiseConfirmX = actionRowX + (ACTION_BTTN_W + ACTION_BTTN_GAP) * 2;

		foldBttn = new SpriteButtonUtil(foldX, actionRowY, null, () ->
		{
			disableActionButtons();
			if (!table.handleAction(table.localSeat, Fold))
				enableHumanActionButtons();
		});
		foldBttn.loadGraphic("assets/images/pokuhbuttons.png", true, ACTION_BTTN_FRAME_W, ACTION_BTTN_FRAME_H);
		foldBttn.animation.add("button", [1]);
		foldBttn.animation.play("button");
		foldBttn.setGraphicSize(Std.int(ACTION_BTTN_W), Std.int(ACTION_BTTN_H));
		foldBttn.updateHitbox();
		add(foldBttn);

		checkCallBttn = new SpriteButtonUtil(checkCallX, actionRowY, null, () ->
		{
			disableActionButtons();
			var action = (table.currentBet - localPlayer.currentBet) > 0 ? Call : Check;
			if (!table.handleAction(table.localSeat, action))
				enableHumanActionButtons();
		});
		checkCallBttn.loadGraphic("assets/images/pokuhbuttons.png", true, ACTION_BTTN_FRAME_W, ACTION_BTTN_FRAME_H);
		checkCallBttn.animation.add("call", [0]);
		checkCallBttn.animation.add("check", [3]);
		checkCallBttn.animation.play("check");
		checkCallBttn.setGraphicSize(Std.int(ACTION_BTTN_W), Std.int(ACTION_BTTN_H));
		checkCallBttn.updateHitbox();
		add(checkCallBttn);

		callAmountText = new FlxText(checkCallX + ACTION_BTTN_W / 2 - AMOUNT_TEXT_W / 2, 0, AMOUNT_TEXT_W, "", 24);
		callAmountText.alignment = CENTER;
		callAmountText.y = amountRowY + (SMALL_BTTN_H - callAmountText.height) / 2;
		add(callAmountText);

		raiseAmountText = new FlxText(raiseConfirmX + ACTION_BTTN_W / 2 - AMOUNT_TEXT_W / 2, 0, AMOUNT_TEXT_W, "$0", 24);
		raiseAmountText.alignment = CENTER;
		raiseAmountText.y = amountRowY + (SMALL_BTTN_H - raiseAmountText.height) / 2;

		raiseMinusBttn = new SpriteButtonUtil(raiseAmountText.x - SMALL_BTTN_W - AMOUNT_TEXT_GAP, amountRowY, null, () ->
		{
			if (pendingRaiseBB > 1)
				pendingRaiseBB--;
			updateRaiseAmountText();
		});
		raiseMinusBttn.loadGraphic("assets/images/pokuhbuttonssmall.png", true, SMALL_BTTN_FRAME_W, SMALL_BTTN_FRAME_H);
		raiseMinusBttn.animation.add("button", [0]);
		raiseMinusBttn.animation.play("button");
		raiseMinusBttn.setGraphicSize(Std.int(SMALL_BTTN_W), Std.int(SMALL_BTTN_H));
		raiseMinusBttn.updateHitbox();
		add(raiseMinusBttn);

		add(raiseAmountText);

		raisePlusBttn = new SpriteButtonUtil(raiseAmountText.x + AMOUNT_TEXT_W + AMOUNT_TEXT_GAP, amountRowY, null, () ->
		{
			pendingRaiseBB++;
			updateRaiseAmountText();
		});
		raisePlusBttn.loadGraphic("assets/images/pokuhbuttonssmall.png", true, SMALL_BTTN_FRAME_W, SMALL_BTTN_FRAME_H);
		raisePlusBttn.animation.add("button", [1]);
		raisePlusBttn.animation.play("button");
		raisePlusBttn.setGraphicSize(Std.int(SMALL_BTTN_W), Std.int(SMALL_BTTN_H));
		raisePlusBttn.updateHitbox();
		add(raisePlusBttn);

		raiseConfirmBttn = new SpriteButtonUtil(raiseConfirmX, actionRowY, null, () ->
		{
			disableActionButtons();
			var target = table.currentBet + pendingRaiseBB * TableManager.BIG_BLIND;
			var action = table.currentBet > 0 ? Raise(target) : Bet(target);
			if (!table.handleAction(table.localSeat, action))
				enableHumanActionButtons();
		});
		raiseConfirmBttn.loadGraphic("assets/images/pokuhbuttons.png", true, ACTION_BTTN_FRAME_W, ACTION_BTTN_FRAME_H);
		raiseConfirmBttn.animation.add("bet", [2]);
		raiseConfirmBttn.animation.add("raise", [4]); // TODO: make functionality for bet and raise pls -MT
		raiseConfirmBttn.animation.play("bet");
		raiseConfirmBttn.setGraphicSize(Std.int(ACTION_BTTN_W), Std.int(ACTION_BTTN_H));
		raiseConfirmBttn.updateHitbox();
		add(raiseConfirmBttn);

		disableActionButtons();

		briefcase = new Briefcase(FlxG.width-240, FlxG.height-60);
		add(briefcase);

		table = new TableManager();
		table.timerManager = timers;

		table.addPlayer("Player", Local);
		dealerSeat = table.addPlayer("Dealer", Bot);

		var botPlayer = new DealerSprite();
		botPlayer.x = FlxG.width/2 - botPlayer.width/2;
		botPlayer.y = 70;
		dealerSprites[dealerSeat] = botPlayer;
		insert(90, botPlayer);

		localPlayer = table.players[table.localSeat];

		for (i in 0...3)
		{
			var itemCard = new ItemCard(50 + i * 50, 2);
			itemCard.alpha = 0;
			FlxTimer.wait(1.1 + i * 0.5, () -> FlxTween.tween(itemCard, {alpha: 1}, 0.5, {ease: FlxEase.quadOut}));
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
		cardDescrIcon.animation.add("ForeSight", [1]);
		cardDescrIcon.animation.add("Debt", [2]);
		cardDescrIcon.animation.add("Strengthener", [3]);
		cardDescrIcon.animation.add("GoldenBullet", [4]);
		cardDescrIcon.animation.add("Intimidation", [5]);
		cardDescrIcon.animation.add("Profit", [6]);
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

		hoverBttns = [
			foldBttn,
			checkCallBttn,
			raiseMinusBttn,
			raisePlusBttn,
			raiseConfirmBttn,
			pauseButton
		];
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		#if (debug && FLX_KEYBOARD)
		if (FlxG.keys.justPressed.NINE)
			grantRandomItem();
		#end

		#if FLX_MOUSE
		for (bttn in hoverBttns)
		{
			if (bttn == null)
				continue;

			if (MouseUtil.isHovering(bttn))
				bttn.alpha = 1.0;
			else
				bttn.alpha = 0.75;
		}
		#end

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

			#if FLX_MOUSE
			var hovering = FlxG.mouse.overlaps(card);

			if (hovering != itemHovered[i])
			{
				itemHovered[i] = hovering;

				if (hovering && card.value != null)
					showCardDescription(card.value);
				else
					hideCardDescription();
			}
			#end

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

	#if FLX_NO_MOUSE
	var cardDescrHideTimer:Null<FlxTimer>;
	#end
	function showCardDescription(item:PlayerItem)
	{
		var descr = itemDescription(item);
		cardDescrIcon.animation.play(descr.name);
		cardDescrText.text = descr.text;

		FlxTween.cancelTweensOf(cardDescrBackground);
		FlxTween.tween(cardDescrBackground, {alpha: 1}, 0.25, {ease: FlxEase.quadOut});

		#if FLX_NO_MOUSE
		if (cardDescrHideTimer != null && cardDescrHideTimer.active)
			cardDescrHideTimer.cancel();
		cardDescrHideTimer = new FlxTimer();
		cardDescrHideTimer.start(10, function(t:FlxTimer) {
			hideCardDescription();
		});
		#end
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
			case ForeSight: {name: "ForeSight", text: "You gain foresight of this round. It reveals the next 3 community cards."};
			case Debt: {name: "Debt", text: "Increases your opponent's debt, focing them to bet double. High risk, high reward."};
			case Strengthener: {name: "Strengthener", text: "Strengthens your weakest hole card by mimicing the strongest card from your opponent's hand."};
			case GoldenBullet: {name: "GoldenBullet", text: "Your life flash before your eyes, as you get saved from elimination with 125 extra chips. Wasted if unused, plan carefully."};
			case Intimidation: {name: "Intimidation", text: "You cock your pistol from your back pouch, your opponent backs off for a while."};
			case Profit: {name: "Profit", text: "Unlimits your bet amount, letting you bet further than what you have."};
		}
	}

	function useItem(item:PlayerItem)
	{
		switch (item)
		{
			case ForeSight:
				var nextCards = table.peekNextCards(3);
				openSubState(new CardsRevealScreen(nextCards));

			case Debt:
				table.armDoubleMinRaise();
				addHistoryText("Debt readied: next raise must be doubled!");

			case Strengthener:
				var swap = table.replaceWeakestHoleCard(table.localSeat);
				if (swap != null)
				{
					if (holeCardSprites[swap.index] != null)
						holeCardSprites[swap.index].reveal(swap.card, true);
					addHistoryText('You upgrade your weakest card to ${CardUtil.formatCardData(swap.card)}!');
				}

			case GoldenBullet:
				goldenBulletArmed = true;
				addHistoryText("Golden Bullet armed for this hand!");

			case Intimidation:
				table.armForcedFold(1 - table.localSeat);
				addHistoryText("Intimidation readied: opponent folds next turn!");

			case Profit:
				table.isRaiseBttnCapped = false;
				addHistoryText('Raise limit for betting has been removed!');
		}
	}

	function doBreifcase() // brought back breifcase + code looked like ahh so i cleaned it up -MT
	{
		if (!breifcaseUpdatable) return;

		var overlaps = #if FLX_NO_KEYBOARD true #else FlxG.mouse.overlaps(briefcase) #end;
		if (overlaps == lastBriefcaseHover) return;

		lastBriefcaseHover = overlaps;
		breifcaseUpdatable = false;

		if (overlaps) {
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
		AudioUtil.playSound('assets/sounds/shuffle${FlxG.random.int(1,3)}.wav');

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
			AudioUtil.playSound('assets/sounds/drop.wav');
			card.reveal(data, false);
		}});

		streetText.text = 'Street: ${table.street}';

		if (localPlayer.holeCards.length + table.community.length >= 7) {
			comboNameText.text = CardUtil.formatCombo(CardUtil.bestHandOf7(localPlayer.holeCards.concat(table.community)));
			comboNameText.alpha = 1.0;
		}
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

		tweenBarColorsTo(targetColor);

		// only lets u uncap 1 turn at a time
		if (!table.isRaiseBttnCapped)
			table.isRaiseBttnCapped = true;

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
		
		if (results.length == 0) {
			addHistoryText("Hand over.");
		} else if (results.length > 1) {
			addHistoryText('Tie!');
		} else for (r in results) {
			addHistoryText('${r.name} wins $$${r.winnings} (${r.handText})');
		}

		var localWon = results.filter(r -> r.seat == table.localSeat).length > 0; // find if localplayer is the winner of this hand/round
		var amountLost = handStartChips - localPlayer.chips;

		if (localWon && !localFolded) // before it only gaev u item if didnt win and didnt fold and you lost like 75 of your chips, now it rewards you for winning and not folding which i think is fair and also fixes the items too rare issue -MT
			grantRandomItem();
	}

	function grantRandomItem()
	{
		var emptySlots = playerItems.filter(c -> c.value == null);
		if (emptySlots.length == 0)
			return;

		var items = [ForeSight, Debt, Strengthener, GoldenBullet, Intimidation, Profit];
		var card = emptySlots[0];
		
		card.setItem(FlxG.random.getObject(items));

		var fullItems = [for (v in playerItems.filter(c -> c.value != null)) v.value];

		if (fullItems.contains(card.value) && Math.random() <= 0.5)
			card.setItem(FlxG.random.getObject(items));

		#if FLX_NO_MOUSE
		if (card.value != null)
			showCardDescription(card.value);
		else
			hideCardDescription();
		#end
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
					table.addChips(table.localSeat, 125);
					addHistoryText("Golden Bullet saves you with 125 chips!");
				}
			}

			var opponent = table.players[1 - table.localSeat];
			var playerWon = opponent.chips <= 0 || localPlayer.chips >= 2400;
			var dealerWon = localPlayer.chips <= 0 || opponent.chips >= 2400;

			if (playerWon != dealerWon) // only one side won
			{
				if (playerWon)
				{
					FlxTween.tween(AudioUtil.gameMusic, {volume: 0}, 1.5);
					FlxTimer.wait(0.5, () -> AudioUtil.playSound("assets/sounds/win.wav"));

					for (s in dealerSprites)
					{
						if (s == null)
							continue;

						s?.preLose();
						FlxTimer.wait(2.5, () -> {
							AudioUtil.playSound("assets/sounds/Shotgun Reload.wav");
						});
						FlxTimer.wait(3.2, () -> {
							AudioUtil.playSound("assets/sounds/SHOT.wav");
							s?.lose();
						});
					}
				}
				else
				{
					for (s in dealerSprites)
						s?.win();

					FlxTween.tween(AudioUtil.gameMusic, {pitch: 0}, 2.5);

					FlxTimer.wait(4.75, () -> {
						AudioUtil.playSound("assets/sounds/SHOT.wav");
						var spr = new FlxSprite();
						spr.makeGraphic(1,1, 0xFFFF0000);
						spr.setGraphicSize(1280*2, 720*2);
						spr.screenCenter();
						AudioUtil.gameMusic.volume = 0;
						AudioUtil.gameMusic.pitch = 1;
						insert(1000, spr);
						FlxTween.color(spr, 0.5, 0xFFFF0000, 0xFF000000, {ease: FlxEase.quadIn});
					});
				}
				persistentUpdate = true;
				openSubState(new GameOverSubState(playerWon));
			}
			else
			{
				comboNameText.text = "(waiting for card river..)";
				comboNameText.alpha = 0.6;

				if ((playerWon && dealerWon) || (!playerWon || !dealerWon)) // both win or both lose
					table.startHand(); // dummy template, do whatever u want here
				else
					table.startHand();
			}
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
		localChipsText.text = 'Your Chips: $$${localPlayer.chips}';
		dealerChipsText.text = 'Dealer\'s Chips: $$${table.players[dealerSeat].chips}';
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
			checkCallBttn.animation.play("call");
			callAmountText.text = '$$$toCall';
		}
		else
		{
			checkCallBttn.animation.play("check");
			callAmountText.text = "";
		}
		/*
			target (pot) = currentBet + pendingRaiseBB × bigBlind
			target:table.pot, currentBet:table.currentBet, bigBlind:Table.BIG_BLIND, pendingRaiseBB
			inverted: pendingRaiseBB = target - currentBet / bigBlind
			/ is prioritized over - , so:
			fixed: pendingRaiseBB = (target - currentBet) / bigBlind
			unfloated: Math.ceil(pendingRaiseBB = (target - currentBet) / bigBlind)
		*/
		pendingRaiseBB = Math.ceil((table.pot - table.currentBet) / TableManager.BIG_BLIND); // 1
		updateRaiseAmountText();

		foldBttn.visible = foldBttn.active = true;
		checkCallBttn.visible = checkCallBttn.active = true;
		callAmountText.visible = true;
		raiseMinusBttn.visible = raiseMinusBttn.active = true;
		raisePlusBttn.visible = raisePlusBttn.active = true;
		raiseConfirmBttn.visible = raiseConfirmBttn.active = true;
		raiseAmountText.visible = true;
	}

	function disableActionButtons()
	{
		foldBttn.visible = foldBttn.active = false;
		checkCallBttn.visible = checkCallBttn.active = false;
		callAmountText.visible = false;
		raiseMinusBttn.visible = raiseMinusBttn.active = false;
		raisePlusBttn.visible = raisePlusBttn.active = false;
		raiseConfirmBttn.visible = raiseConfirmBttn.active = false;
		raiseAmountText.visible = false;
	}

	function updateRaiseAmountText()
	{
		var target = table.currentBet + pendingRaiseBB * TableManager.BIG_BLIND;
		var maxRaise = localPlayer.currentBet + localPlayer.chips; // how much we have = whats left + how much we bet/use

		trace('localBet: ${localPlayer.currentBet}, localChips ${localPlayer.chips}, target: $target, maxRaise: $maxRaise');

		if (table.isRaiseBttnCapped && target > maxRaise) { // cap raise
			pendingRaiseBB--;
			return;
		}
		if (table.pot > target) { // cap reduce
			pendingRaiseBB++;
			return;
		}
		raiseAmountText.text = '$$$target';
	}
}

enum PlayerItem
{
	/**
		Reveals the next 3 community cards
	**/
	ForeSight;

	/**
		The next player must raise the bet to at least double the previous raise (or 20)
	**/
	Debt;

	/**
		Replaces your weakest card with the strongest card present in the current hand
	**/
	Strengthener;

	/**
		saves you from elimination by giving you 125 extra chips upon losing all credits, but only works if you lose to the current round, next round will be useless
	**/
	GoldenBullet;

	/**
		Makes the next player automatically fold their hand
	**/
	Intimidation;

	/**
		Lets you bet further than what you have
	**/
	Profit;
}
