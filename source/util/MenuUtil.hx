package util;

import flixel.FlxBasic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import util.MouseUtil;

/** made this since i saw a bunch of repeated utils so i merged them into one menuutil cuz clean -MT **/
class MenuUtil
{
    /** replacement for the hardcoded `confirm()` function  -MT **/
    var actions = new Map<String, Void->Void>();

    /** Names of the buttons to click, static because i think this is good -LeonGamerPS1 **/
    public var buttonList:Array<String> = [];
    /** support for pausemenu's color attribute -MT **/
    public var buttonColor:Int = FlxColor.WHITE;
    /** item related stuff **/
    public var buttonGroup:FlxTypedGroup<FlxText>;

    var hoverList:Map<FlxBasic, Bool> = [];

    public function new(buttonList:Array<String>, buttonColor:Int = FlxColor.WHITE)
    {
        this.buttonList = buttonList;
        this.buttonColor = buttonColor;
    }

    /** 
        use this to iterate over the group and make flxtexts inside it -MT 
        @param buttonGroup the `new FlxTypedGroup<FlxText>` button from your `FlxState`
    **/
    public function makeButtonGroup(buttonGroup:FlxTypedGroup<FlxText>)
    {
        this.buttonGroup = buttonGroup;
        for (buttonName in buttonList)
		{
			var button:FlxText = new FlxText(0, 0, 0, buttonName);
			button.size = 20;
			button.color = buttonColor;
			button.screenCenter();
			button.y += button.height * buttonGroup.length * 1.25 + 10;
			buttonGroup.add(button);

            hoverList.set(button, false);
		}
    }

    /** 
        sets up what gets called inside -MT
        @param name the name of the callback (preference)
        @param callback the function that gets called when said flxtext is triggered (use `() -> mycoolthing(that)` instead of `mycoolthing(that)`)
    **/
    public inline function addConfirmOption(name:String, callback:Void->Void)
        actions.set(name, callback);

    /** too lazy to make this a state or flxbasic or something so just place this inside your `update()` loop -MT **/
    public function updateLoop()
    {
        if (buttonGroup == null || !actions.keys().hasNext()) // empty
            return;

        for (item in buttonGroup)
            if (MouseUtil.justClicked(item))
            {
                // AudioUtil.playSound('assets/sounds/ui/click.wav');
				confirm(item.text);
            }
            else
            {
                if (MouseUtil.isHovering(item))
                {
                    if (hoverList.get(item) == false)
                    {
                        hoverList.set(item, true);
                        // AudioUtil.playSound('assets/sounds/ui/hover.wav');
						item.scale.setXY(1.1);
                    }
                }
                else if (hoverList.get(item) == true)
				{
                    hoverList.set(item, false);
					item.scale.setXY(1);
				}
            }
    }

    inline function confirm(name:String)
        if (actions.exists(name))
            actions.get(name)();
}