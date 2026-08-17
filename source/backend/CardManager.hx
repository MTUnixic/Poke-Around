package backend;

import ds.Pool;

typedef CardData =
{
	num:Int,
	suit:Int,
}

class CardManager
{
	static var cardPool:Pool<CardData> =
		{
			var p = new Pool<CardData>();
			for (suit in 0...4)
				for (num in 1...14)
					p.add({suit: suit, num: num});
			p;
		};

	public static var cards:Array<CardData> = [];

	// every way to choose 5 indices out of 7, used by bestHandOf7
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

	public static function freshShuffledDeck():Array<CardData>
	{
		return cardPool.getMultiple(52, true, false);
	}

	// best 5-card hand out of exactly 7 cards (e.g. 2 hole + 5 community)
	public static function bestHandOf7(cards:Array<CardData>)
	{
		var best = {rank: -1, num1: -1, num2: -1};
		for (combo in sevenChooseFive)
		{
			var hand = [for (i in combo) cards[i]];
			var result = checkCombos(hand);
			if (result.rank > best.rank
				|| (result.rank == best.rank && result.num1 > best.num1)
				|| (result.rank == best.rank && result.num1 == best.num1 && result.num2 > best.num2))
				best = result;
		}
		return best;
	}

	public static function formatCombo(c:{rank:Int, num1:Int, num2:Int})
	{
		return switch (c.rank)
		{
			default:
				'High Card ${c.num1}';
			case 1:
				'Pair ${c.num1}';
			case 2:
				'Two Pair ${c.num1},${c.num2}';
			case 3:
				'Three of a Kind ${c.num1}';
			case 4:
				'Straight ${c.num1}';
			case 5:
				'Flush';
			case 6:
				'Full House ${c.num1},${c.num2}';
			case 7:
				'Four of a Kind ${c.num1}';
			case 8:
				'Straight Flush ${c.num1}';
			case 9:
				'Royal Flush';
		}
	}

	public static function checkCombos(cards:Array<CardData>)
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
						result.num1 = num; // high card
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
				default://any hand with 5 equal cards or more is just higher than everything, fuck it
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
