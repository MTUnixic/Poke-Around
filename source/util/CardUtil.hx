package util;

import ds.Pool;

typedef CardData =
{
	num:Int,
	suit:Int,
}

private typedef CardCombo = {
	var rank:Int;
	var num1:Int;
	var num2:Int;
}

class CardUtil
{
	static var cardPool:Pool<CardData> =
		{
			var p = new Pool<CardData>();
			for (suit in 0...4)
				for (num in 1...14)
					p.add({suit: suit, num: num});
			p;
		};

	/** an array of CardData (with their nums and suits) **/
	public static var cards:Array<CardData> = [];

	/** every way to choose 5 indices out of 7, used by bestHandOf7 **/
	static var sevenChooseFive:Array<Array<Int>> = {
		var combos:Array<Array<Int>> = [];
		for (a in 0...7)
			for (b in (a + 1)...7)
				for (c in (b + 1)...7)
					for (d in (c + 1)...7)
						for (e in (d + 1)...7)
							combos.push([a, b, c, d, e]);
		combos;
	}

	public static inline function freshShuffledDeck():Array<CardData>
		return cardPool.getMultiple(52, true, false);

	/** best 5-card hand out of exactly 7 cards (e.g. 2 hole + 5 community) **/
	public static function bestHandOf7(cards:Array<CardData>):CardCombo
	{
		var best = {rank: -1, num1: -1, num2: -1};
		for (combo in sevenChooseFive)
		{
			var hand = [for (i in combo) cards[i]];
			var result = findCombosFromCards(hand);
			if (result.rank > best.rank
				|| (result.rank == best.rank && result.num1 > best.num1)
				|| (result.rank == best.rank && result.num1 == best.num1 && result.num2 > best.num2)
			) best = result;
		}
		return best;
	}

	/** stringifies CardData into pairs (e.g. "Ace Clubs", "Queen Hearts", etc.) **/
	public static function formatCardData(c:CardData):String
	{
		var rank = formatRank(c.num);
		var suit = formatSuit(c.suit);

		return '$rank of $suit';
	}

	static function formatRank(rank:Int, isMany = false):String
	{
		return switch (rank)
		{
			case 1: "Ace" + (isMany? "s" : "");
			case 11: "Jack" + (isMany? "s" : "");
			case 12: "Queen" + (isMany? "s" : "");
			case 13: "King" + (isMany? "s" : "");
			default: '${formatNumbers(rank, isMany)}';
		};
	}

	static inline function formatSuit(rank:Int):String
	{
		return switch (rank)
		{
			case 0: "Clubs";
			case 1: "Diamonds";
			case 2: "Hearts";
			default: "Spades";
		};
	}

	static inline function formatNumbers(num:Int, isMany = false):String
	{
		final worded =  switch (num)
		{
			case 2: "Two";
			case 3: "Three";
			case 4: "Four";
			case 5: "Five";
			case 6: "Six";
			case 7: "Seven";
			case 8: "Eight";
			case 9: "Nine";
			case 10:"Ten";
			default: "" + num;
		};

		if (!isMany) return worded;
		if (num == 0) return worded + "es";

		return worded + "s";
	}

	/** stringifies CardCombo into their names (e.g. High Card, Pair, etc.) **/
	public static function formatCombo(c:CardCombo):String {
		final x = formatRank(c.num1), y = formatRank(c.num2);
		final xs = formatRank(c.num1,true), ys = formatRank(c.num2,true);

		return switch (c.rank)
		{
			default:'High Card ($x)';
			case 1: 'Pair of $xs';
			case 2: 'Two Pairs of $xs over $ys';
			case 3: 'Three of a Kind ($xs)';
			case 4: '$x-high Straight';
			case 5: 'Flush';
			case 6: 'Full House of $xs over $ys';
			case 7: 'Four of a Kind ($xs)';
			case 8: 'Straight Flush ($x)';
			case 9: 'Royal Flush';
		}
	}

	/** evaluates your hand and tells you what combo combination it is **/
	public static function findCombosFromCards(cards:Array<CardData>):CardCombo
	{
		var result = {rank: 0, num1: 0, num2: 0};
		var nums:Map<Int, Int> = [];
		var suits:Map<Int, Int> = [];
		for (card in cards)
		{
			nums.set(card.num, nums.exists(card.num) ? nums.get(card.num) + 1 : 1);
			suits.set(card.suit, suits.exists(card.suit) ? suits.get(card.suit) + 1 : 1);
		}
		for (num => frequency in nums)
		{
			switch (frequency)
			{
				case 1:
					if (result.rank == 0)
						result.num1 = num == 1 ? 14 : Std.int(Math.max(result.num1, num)); // high card // ace is stored as 1 so this stops it from getting neglected, and math.max stops any inferior combo from overriding any strong combos (stops high cards and such from not working at all) -MT
				case 2:
					if (result.rank == 0) // pair
					{
						result.num1 = num;
						result.rank = 1;
					}
					else if (result.rank == 1) // twopair
					{
						result.num2 = num;
						result.rank = 2;
					}
					else if (result.rank == 3) // fullhouse
					{
						result.rank = 6;
						result.num2 = num;
					}
				case 3:
					if (result.rank == 1) // upgrade existing pair to a full house
					{
						result.rank = 6;
						result.num2 = result.num1; // previous pair becomes the "pair" part
						result.num1 = num; // new triple becomes the "trips" part
					}
					else if (result.rank < 3) // three of a kind (no pair recorded yet)
					{
						result.rank = 3;
						result.num1 = num;
					}
				case 4:
					if (result.rank < 7)
					{
						result.rank = 7;
						result.num1 = num;
					}
				default: // any hand with 5 equal cards or more is just higher than everything, fuck it
					var rank = 9 + (frequency - 4);
					if (result.rank < rank)
					{
						result.num1 = num;
						result.rank = rank;
					}
			}
		}
		if (result.rank < 10)
		{
			var maxConsecutive = 0;
			var consecutive = 0;
			var lastNum = 0;
			for (i in 1...14)
			{
				nums.exists(i) ? consecutive++ : consecutive = 0;
				if (consecutive > maxConsecutive)
				{
					maxConsecutive = consecutive;
					lastNum = i;
				}
			}
			if (consecutive == 4 && nums.exists(1))
			{
				maxConsecutive;
				lastNum = 1;
			}
			if (maxConsecutive == 5)
			{
				if (result.rank < 4)
				{
					result.rank = 4;
					result.num1 = lastNum;
				}
			}
			for (i in 0...3)
			{
				if (suits.get(i) == 5)
				{
					if (result.rank == 4)
						result.rank = 8;
					else if (result.rank < 5)
						result.rank = 5;
					if (lastNum == 1)
					{
						result.rank = 9;
					}
				}
			}
		}

		return result;
	}
}
