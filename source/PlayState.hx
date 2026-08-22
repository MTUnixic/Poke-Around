package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.util.FlxTimer;
import menus.PauseMenu;
import objects.Briefcase;
import objects.Card;
import objects.Table.PlayerAction;
import objects.Table.PokerPlayer;
import objects.Table.ShowdownResult;
import objects.Table;
import util.CardUtil.CardData;

class PlayState extends CoolBG
{
	static inline var POT_X = 596.0;
	static inline var POT_Y = 260.0;
	static inline var HOLE_Y = 520.0;
	static inline var COMMUNITY_Y = 260.0;

	var table:Table;
	var localPlayer:PokerPlayer;

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

	var briefcase:Briefcase;

	var pendingRaiseBB:Int = 1;
	var pauseButton:FlxSprite;

	override public function create()
	{
		super.create();

		potText = new FlxText(POT_X - 60, POT_Y + 130, 200, "Pot: 0", 20);
		add(potText);

		chipsText = new FlxText(120, 200, 300, "Chips: 0", 20);
		add(chipsText);

		streetText = new FlxText(20, 20, 400, "Street: waiting", 20);
		add(streetText);

		foldBtn = new FlxButton(40, 100, "Fold", () ->
		{
			disableActionButtons();
			table.handleAction(table.localSeat, Fold);
		});
		add(foldBtn);

		checkCallBtn = new FlxButton(40, 120, "Check", () ->
		{
			disableActionButtons();
			var action = (table.currentBet - localPlayer.currentBet) > 0 ? Call : Check;
			table.handleAction(table.localSeat, action);
		});
		add(checkCallBtn);

		raiseMinusBtn = new FlxButton(40, 140, "-", () ->
		{
			if (pendingRaiseBB > 1)
				pendingRaiseBB--;
			updateRaiseAmountText();
		});
		raiseMinusBtn.setGraphicSize(20, 20);
		raiseMinusBtn.updateHitbox();
		add(raiseMinusBtn);

		raiseAmountText = new FlxText(80, 140, 80, "0", 16);
		raiseAmountText.alignment = CENTER;
		add(raiseAmountText);

		raisePlusBtn = new FlxButton(120, 140, "+", () ->
		{
			pendingRaiseBB++;
			updateRaiseAmountText();
		});
		raisePlusBtn.setGraphicSize(20, 20);
		raisePlusBtn.updateHitbox();
		add(raisePlusBtn);

		raiseConfirmBtn = new FlxButton(40, 160, "Bet/Raise", () ->
		{
			disableActionButtons();
			var target = table.currentBet + pendingRaiseBB * Table.BIG_BLIND;
			var action = table.currentBet > 0 ? Raise(target) : Bet(target);
			table.handleAction(table.localSeat, action);
		});
		add(raiseConfirmBtn);

		disableActionButtons();

		briefcase = new Briefcase(FlxG.width - 400, FlxG.height - 80);
		add(briefcase);

		table = new Table();

		table.addPlayer("You", Local);
		table.addPlayer("Dealer", Bot);

		localPlayer = table.players[table.localSeat];
		
		table.onDeal = onDeal;
		table.onCommunityCard = onCommunityCard;
		table.onPotChanged = onPotChanged;
		table.onTurnChanged = onTurnChanged;
		table.onPlayerActed = onPlayerActed;
		table.onShowdown = onShowdown;
		table.onHandOver = onHandOver;

		table.startHand();

		pauseButton = new FlxSprite(0, 0,
			'assets/images/placeholderpause.png'); // TODO: MT can you please draw it if you want to ofc but leave the old one it in incase someone snoops in files
		pauseButton.x = FlxG.width - pauseButton.width;
		add(pauseButton);
	}

	var lastBriefcaseHover:Bool = false;
	var isBriefcaseHovered:Bool = false;
	var canUpdateBriefcasePos:Bool = true;
	override public function update(elapsed:Float)
	{
		if (canUpdateBriefcasePos)
		{
			isBriefcaseHovered = FlxG.mouse.x > briefcase.x - 20 && FlxG.mouse.x < briefcase.x + briefcase.width + 20 && FlxG.mouse.y > briefcase.y - 20 && FlxG.mouse.y < briefcase.y + briefcase.height + 20;
			if (isBriefcaseHovered != lastBriefcaseHover)
			{
				lastBriefcaseHover = isBriefcaseHovered;
				canUpdateBriefcasePos = false;
				if (isBriefcaseHovered)
					FlxTween.tween(briefcase, { y: FlxG.height - 300}, 0.5, { ease: FlxEase.quadOut, onComplete: function(tween:FlxTween) {
						canUpdateBriefcasePos = true;
					}});
				else
					FlxTween.tween(briefcase, { y: FlxG.height - 80}, 0.5, { ease: FlxEase.quadOut, onComplete: function(tween:FlxTween) {
						canUpdateBriefcasePos = true;
					}});
			}
		}
		super.update(elapsed);
		if (FlxG.mouse.overlaps(pauseButton) && FlxG.mouse.justPressed) // pausing
			openSubState(new PauseMenu());
	}

	function onDeal()
	{
		killHoleCards();
		killCommunityCards();

		for (i in 0...localPlayer.holeCards.length)
		{
			var card = new Card();
			card.x = 90 + (i * 150);
			card.y = FlxG.height;
			card.z = 60;
			add(card);
			holeCardSprites.push(card);

			var data = localPlayer.holeCards[i];

			FlxTween.tween(card, { y: FlxG.height - card.height - 70 }, 0.75, { ease: FlxEase.quadOut, onComplete: function(tween:FlxTween) {
				card.reveal(data, true);
			}});
		}

		streetText.text = 'Street: ${table.street}';
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

		streetText.text = 'Street: ${table.street}';
	}

	function onPotChanged()
	{
		potText.text = 'Pot: ${table.pot}';
		refreshChipsText();
	}

	function onTurnChanged(seat:Int)
	{
		if (table.players[seat].isBot)
			disableActionButtons();
		else
			enableHumanActionButtons();
	}

	function onPlayerActed(seat:Int, action:PlayerAction)
	{
		if (seat == table.localSeat)
			switch (action)
			{
				case Fold: killHoleCards();
				default:
			}

		refreshChipsText();
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
			if (table.playersWithChips() < 2)
				FlxG.resetState();
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

	function enableHumanActionButtons()
	{
		var toCall = table.currentBet - localPlayer.currentBet;
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
		var target = table.currentBet + pendingRaiseBB * Table.BIG_BLIND;
		raiseAmountText.text = '$target';
	}
}