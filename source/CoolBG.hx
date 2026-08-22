package;

import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxBackdrop;

class CoolBG extends FlxState
{
    var glow:FlxSprite;
    var frame:FlxSprite;
	var pokerTable:FlxSprite;

    var diam:FlxBackdrop;
    var squa:FlxBackdrop;
    
    override function create() {
        super.create();

        final bg = new FlxSprite();
        bg.loadGraphic('assets/images/coolbg/pokuhbg.png');
        bg.screenCenter();
        add(bg);

        diam = new FlxBackdrop('assets/images/coolbg/pokuhdiam.png');
        diam.velocity.setXY(50);
        diam.alpha = scratchGhost2Flixel(92);
        add(diam);

        squa = new FlxBackdrop('assets/images/coolbg/pokuhsqua.png');
        squa.velocity.setXY(-50);
        squa.alpha = scratchGhost2Flixel(95);
        add(squa);

        frame = new FlxSprite();
        frame.loadGraphic('assets/images/coolbg/pokuhbgframe.png');
        add(frame);

        glow = new FlxSprite();
        glow.loadGraphic('assets/images/coolbg/pokuhbgglow.png');
        glow.alpha = scratchGhost2Flixel(40);
        add(glow);

        pokerTable = new FlxSprite();
        pokerTable.loadGraphic('assets/images/pokuhtable.png');
		pokerTable.setGraphicSize(pokerTable.width * 2.75, pokerTable.height * 2.75);
		pokerTable.updateHitbox();
        pokerTable.screenCenter();
		pokerTable.y += 140;
        insert(100, pokerTable);
    }

    /** too lazy to do the math **/
    inline function scratchGhost2Flixel(ghost:Int):Float
        return 1 - ( ghost / 100 );
}